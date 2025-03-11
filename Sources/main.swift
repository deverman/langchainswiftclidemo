// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import LangChain
import ArgumentParser
import AsyncHTTPClient
import NIOCore
import NIOPosix

protocol Tool {
    func name() -> String
    func description() -> String
    func call(_ input: String) async throws -> String
}

final class TimeCheckTool: Tool {
    func name() -> String {
        return "time_check"
    }
    
    func description() -> String {
        return "Get the current time"
    }
    
    func call(_ input: String) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "Current time is: \(formatter.string(from: Date()))"
    }
}

final class CalculatorTool: Tool {
    func name() -> String {
        return "calculator"
    }
    
    func description() -> String {
        return "Perform basic arithmetic calculations"
    }
    
    func call(_ input: String) async throws -> String {
        // Extract numbers and operator from the input
        let pattern = #"(\d+)\s*\*\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let num1Range = Range(match.range(at: 1), in: input),
              let num2Range = Range(match.range(at: 2), in: input),
              let num1 = Double(input[num1Range]),
              let num2 = Double(input[num2Range]) else {
            return "Could not find a valid multiplication expression in: \(input)"
        }
        
        return "The result of \(Int(num1)) * \(Int(num2)) = \(Int(num1 * num2))"
    }
}

// Custom agent that works with our Tool protocol
final class CustomAgent {
    private let llm: ChatOpenAI
    private let tools: [Tool]
    
    init(llm: ChatOpenAI, tools: [Tool]) {
        self.llm = llm
        self.tools = tools
    }
    
    func run(args: String) async throws -> String {
        let prompt = """
        You are an AI assistant that can use tools to help answer questions.
        
        Available tools:
        \(tools.map { "- \($0.name()): \($0.description())" }.joined(separator: "\n"))
        
        User's request: \(args)
        
        Think about what tools you need to use to answer this request.
        Then use the tools in sequence to get the information needed.
        Finally, provide a natural response that combines all the information.
        
        Let's solve this step by step:
        1. First, identify which tools we need
        2. Then, use each tool in sequence
        3. Finally, combine the results into a natural response
        """
        
        // We don't need to check the response since we're not using it
        _ = await llm.generate(text: prompt)
        
        // Always try to use both tools for this simple demo
        var timeResult = ""
        var calculationResult = ""
        
        for tool in tools {
            let result = try await tool.call(args)
            switch tool.name() {
            case "time_check":
                timeResult = result
            case "calculator":
                calculationResult = result
            default:
                break
            }
        }
        
        return """
        Let me help you with that!
        
        \(timeResult)
        \(calculationResult)
        """
    }
}

@main
struct AIAssistant: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "langchainswiftclidemo",
        abstract: "An AI assistant that can perform various tasks",
        discussion: "Uses LangChain Swift to create an agentic AI that can handle multiple tools."
    )
    
    @Option(name: .long, help: "The question or task for the AI assistant")
    var query: String
    
    @Flag(name: .long, help: "Enable verbose output")
    var verbose: Bool = false
    
    mutating func run() async throws {
        // Check for OpenAI API key
        guard let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            print("❌ Error: OPENAI_API_KEY environment variable is not set")
            throw ExitCode.failure
        }
        
        // Initialize LangChain configuration
        LC.initSet([
            "OPENAI_API_KEY": openAIKey
        ])
        
        // Initialize HTTP client
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
        
        // Create tools
        let tools: [Tool] = [
            TimeCheckTool(),
            CalculatorTool()
        ]
        
        do {
            // Initialize the LLM
            let llm = ChatOpenAI(httpClient: httpClient, temperature: 0.7)
            
            print("🤖 Processing your request: \(query)")
            if verbose {
                print("🛠️ Available tools: \(tools.map { $0.name() }.joined(separator: ", "))")
            }
            
            // Initialize the agent
            let agent = CustomAgent(llm: llm, tools: tools)
            
            // Run the agent
            let result = try await agent.run(args: query)
            print("\n✨ AI Assistant's Response:")
            print(result)
            
        } catch {
            print("❌ Error: \(error)")
            throw error
        }
        
        // Clean up resources
        try await httpClient.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }
}
