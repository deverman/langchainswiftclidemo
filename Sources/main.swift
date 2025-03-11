// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser
import LangChain
import LangGraph
import AsyncHTTPClient
import NIOCore
import NIOPosix

// MARK: - Architecture Overview
/// This file implements an agentic AI system using LangChain and LangGraph.
/// The system consists of these main components:
/// 1. State Management (AssistantState)
/// 2. Tool System (Tool protocol and implementations)
/// 3. Query Processing (QueryProcessor)
/// 4. Command Line Interface (AIAssistant)
///
/// The workflow is:
/// 1. User provides a query through CLI
/// 2. QueryProcessor uses LLM to select appropriate tools
/// 3. Selected tools are executed in sequence
/// 4. Results are combined and returned to user

// MARK: - Agent State
/// This struct defines the state management for our LangGraph workflow.
/// LangGraph uses a state-based approach where each node in the workflow can access and modify the state.
/// The state channels define what data can be stored and passed between nodes.
struct AssistantState: AgentState {
    // Define schema for state channels
    // These channels determine what data can be stored in the state:
    // - messages: Stores the final responses
    // - intermediate_steps: Stores tool execution steps
    // - agent_outcome: Stores the final outcome of the agent
    // - isDone: Tracks if the workflow is complete
    static var schema: Channels = {
        [
            "messages": AppenderChannel<String>(),
            "intermediate_steps": AppenderChannel<(AgentAction, String)>(),
            "agent_outcome": AppenderChannel<AgentFinish>(),
            "isDone": AppenderChannel<Bool>()
        ]
    }()
    
    var data: [String: Any]
    
    init(_ initState: [String: Any]) {
        self.data = initState
    }
    
    var input: String? {
        value("input")
    }
    
    var messages: [String]? {
        value("messages")
    }
    
    var intermediateSteps: [(AgentAction, String)]? {
        value("intermediate_steps")
    }
    
    var agentOutcome: AgentFinish? {
        value("agent_outcome")
    }
    
    var isDone: Bool? {
        value("isDone")
    }
}

// MARK: - Agent Types
/// These types define the structure of actions and outcomes in our LangGraph workflow.
/// They help standardize how tools are called and how results are returned.
struct AgentAction {
    let toolName: String
    let toolInput: String
}

struct AgentFinish {
    let returnValues: [String: String]
}

// MARK: - Tool Protocol
/// The Tool protocol defines the interface that all tools must implement.
/// This is a key concept in LangChain - tools are the building blocks that agents can use
/// to perform specific tasks. Each tool has a name, description, and a run method.
///
/// To create a new tool:
/// 1. Create a new class implementing this protocol
/// 2. Implement name() and description() to help the LLM understand when to use your tool
/// 3. Implement run() with your tool's logic
/// 4. Add your tool to the tools array in AIAssistant.run()
protocol Tool {
    func name() -> String
    func description() -> String
    func run(_ input: String) async throws -> String
}

// MARK: - Time Check Tool
/// A simple example tool that demonstrates how to create a custom tool.
/// This tool uses the system's date formatter to get the current time.
class TimeCheckTool: Tool {
    func name() -> String {
        return "time_check"
    }
    
    func description() -> String {
        return "Get the current time in HH:mm:ss format"
    }
    
    func run(_ input: String) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Calculator Tool
/// Another example tool that shows how to handle more complex input processing.
/// This tool demonstrates:
/// - Input validation using regular expressions
/// - Error handling with descriptive messages
/// - Clear input format requirements
class CalculatorTool: Tool {
    func name() -> String {
        return "calculator"
    }
    
    func description() -> String {
        return "Multiply two numbers (format: number * number)"
    }
    
    func run(_ input: String) async throws -> String {
        // Extract numbers using regular expression
        let pattern = #"(\d+)\s*\*\s*(\d+)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        
        guard let match = regex.firstMatch(in: input, range: range),
              let num1Range = Range(match.range(at: 1), in: input),
              let num2Range = Range(match.range(at: 2), in: input),
              let num1 = Int(input[num1Range]),
              let num2 = Int(input[num2Range]) else {
            throw NSError(domain: "Calculator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid input format. Expected: number * number"])
        }
        
        return "\(num1 * num2)"
    }
}

// MARK: - Query Processor
/// The QueryProcessor class is the main orchestrator of our LangGraph workflow.
/// It handles:
/// 1. LLM initialization and configuration
/// 2. Tool selection based on user input
/// 3. Tool execution and result aggregation
/// 4. Resource management (HTTP client, event loop)
final class QueryProcessor {
    private let tools: [Tool]
    private let llm: ChatOpenAI
    private let toolSelectionChain: LLMChain
    private let httpClient: HTTPClient
    private let eventLoopGroup: EventLoopGroup
    private var isShutdown: Bool = false
    
    init(tools: [Tool]) throws {
        self.tools = tools
        // Initialize with a single thread for our simple use case
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        // Use shared event loop group to prevent resource leaks
        self.httpClient = HTTPClient(eventLoopGroupProvider: .shared(self.eventLoopGroup))
        self.llm = ChatOpenAI(httpClient: httpClient, temperature: 0.8)
        
        // Create tool selection chain with a prompt that helps the LLM understand
        // when to use each tool based on their descriptions
        let toolDescriptions = tools.map { "- \($0.name()): \($0.description())" }.joined(separator: "\n")
        let template = """
        You are a helpful AI assistant that can use various tools to help users.
        Based on the user's input, select the most appropriate tool(s) to use.
        
        Available tools:
        \(toolDescriptions)
        
        User input: {input}
        
        Select the most appropriate tool(s) to use. If multiple tools are needed, list each one on a new line.
        Only respond with the tool names, nothing else.
        """
        
        self.toolSelectionChain = LLMChain(
            llm: llm,
            prompt: PromptTemplate(
                input_variables: ["input"],
                partial_variable: [:],
                template: template
            )
        )
    }
    
    deinit {
        shutdown()
    }
    
    /// Gracefully shuts down HTTP client and event loop group
    func shutdown() {
        guard !isShutdown else { return }
        isShutdown = true
        
        // Shutdown HTTP client first
        try? httpClient.syncShutdown()
        
        // Then shutdown event loop group
        try? eventLoopGroup.syncShutdownGracefully()
    }
    
    /// Processes a user query by:
    /// 1. Using the LLM to select appropriate tools
    /// 2. Executing the selected tools
    /// 3. Combining and returning the results
    func process(_ input: String) async throws -> String {
        defer {
            // Ensure resources are cleaned up after processing
            shutdown()
        }
        
        print("\n🤖 Processing query: \"\(input)\"")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        var responses: [String] = []
        
        // Use LLM to select appropriate tools
        print("📝 Asking LLM to select tools...")
        guard let toolSelectionResult = try await toolSelectionChain.predict(args: ["input": input]) else {
            throw NSError(domain: "Assistant", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get tool selection from LLM"])
        }
        
        // Parse tool names from LLM response
        let selectedToolNames = toolSelectionResult
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        print("✅ LLM selected tools: \(selectedToolNames.map { "'\($0)'" }.joined(separator: ", "))")
        
        // Execute selected tools
        for toolName in selectedToolNames {
            if let tool = tools.first(where: { $0.name() == toolName }) {
                print("\n🔧 Executing tool: '\(tool.name())'")
                print("📥 Input: \"\(input)\"")
                let result = try await tool.run(input)
                print("📤 Output: \"\(result)\"")
                responses.append(result)
            }
        }
        
        print("\n✨ Final combined output:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        return responses.joined(separator: "\n")
    }
}

// MARK: - Command Line Interface
/// The main entry point for our CLI tool.
/// This uses ArgumentParser to handle command-line arguments and
/// coordinates the overall flow of the application.
@main
struct AIAssistant: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "langchainswiftclidemo",
        abstract: "A CLI tool for interacting with LangChain"
    )
    
    @Option(name: .long, help: "Your question")
    var query: String?
    
    @Flag(name: .long, help: "Show available tools")
    var verbose: Bool = false
    
    mutating func validate() throws {
        if !verbose && query == nil {
            throw ValidationError("Either --query or --verbose must be provided")
        }
        
        // Validate OpenAI API key
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            throw ValidationError("OPENAI_API_KEY environment variable is not set")
        }
        
        // Initialize LangChain with API key
        LC.initSet(["OPENAI_API_KEY": apiKey])
    }
    
    func run() async throws {
        // Initialize available tools
        // To add a new tool:
        // 1. Create a class implementing the Tool protocol
        // 2. Add an instance of your tool to this array
        let tools: [any Tool] = [
            TimeCheckTool(),
            CalculatorTool()
        ]
        
        if verbose {
            print("Available tools:")
            for tool in tools {
                print("- \(tool.name()): \(tool.description())")
            }
            if query == nil {
                return
            }
        }
        
        if let query = query {
            let processor = try QueryProcessor(tools: tools)
            let result = try await processor.process(query)
            print("\nFinal output:")
            print(result)
        }
    }
}

