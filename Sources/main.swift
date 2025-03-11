// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import LangChain
import ArgumentParser
import AsyncHTTPClient
import NIOCore
import NIOPosix

// MARK: - Tool Protocol
/// Define a simple protocol for our tools to implement
protocol Tool {
    func name() -> String
    func description() -> String
    func call(_ input: String) async throws -> String
}

// MARK: - Time Check Tool
/// A simple tool that returns the current time
final class TimeCheckTool: Tool {
    func name() -> String {
        return "time_check"
    }
    
    func description() -> String {
        return "Get the current time in HH:mm:ss format"
    }
    
    func call(_ input: String) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "Current time is: \(formatter.string(from: Date()))"
    }
}

// MARK: - Calculator Tool
/// A basic calculator tool that handles multiplication
final class CalculatorTool: Tool {
    func name() -> String {
        return "calculator"
    }
    
    func description() -> String {
        return "Multiply two numbers (format: number * number)"
    }
    
    func call(_ input: String) async throws -> String {
        // Simple regex to extract multiplication expression
        let pattern = #"(\d+)\s*\*\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let num1Range = Range(match.range(at: 1), in: input),
              let num2Range = Range(match.range(at: 2), in: input),
              let num1 = Int(input[num1Range]),
              let num2 = Int(input[num2Range]) else {
            return "Please provide two numbers to multiply (e.g., '5 * 3')"
        }
        
        return "\(num1) * \(num2) = \(num1 * num2)"
    }
}

// MARK: - Assistant Implementation
/// A simple AI assistant that can use tools to answer questions
final class Assistant {
    private let llm: ChatOpenAI
    private let tools: [Tool]
    
    init(llm: ChatOpenAI, tools: [Tool]) {
        self.llm = llm
        self.tools = tools
    }
    
    func process(query: String) async throws -> String {
        var responses: [String] = []
        
        // Try each tool with the query
        for tool in tools {
            if let result = try? await tool.call(query) {
                responses.append(result)
            }
        }
        
        // Combine all responses
        return responses.joined(separator: "\n")
    }
}

// MARK: - Command Line Interface
@main
struct AIAssistant: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "langchainswiftclidemo",
        abstract: "A simple AI assistant that can tell time and do calculations",
        discussion: "Example: Run with --query 'What time is it and calculate 5 * 3'"
    )
    
    @Option(name: .long, help: "Your question (e.g., 'What time is it?' or 'Calculate 5 * 3')")
    var query: String?
    
    @Flag(name: .long, help: "Show available tools and detailed output")
    var verbose: Bool = false
    
    mutating func validate() throws {
        if query == nil && !verbose {
            throw ValidationError("Either --query or --verbose must be provided")
        }
    }
    
    mutating func run() async throws {
        // Create tools
        let tools: [Tool] = [TimeCheckTool(), CalculatorTool()]
        
        // If verbose mode is enabled, show available tools
        if verbose {
            print("🛠️ Available tools:")
            for tool in tools {
                print("- \(tool.name()): \(tool.description())")
            }
            print()
            
            // If no query is provided, we're done
            if query == nil {
                return
            }
        }
        
        // Verify API key is set
        guard let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            print("❌ Please set your OPENAI_API_KEY environment variable")
            throw ExitCode.failure
        }
        
        // Initialize LangChain
        LC.initSet(["OPENAI_API_KEY": openAIKey])
        
        // Setup networking
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
        
        do {
            // Process the query if provided
            if let query = query {
                print("🤖 Processing: \(query)\n")
                let assistant = Assistant(llm: ChatOpenAI(httpClient: httpClient), tools: tools)
                let result = try await assistant.process(query: query)
                print("✨ Response:\n\(result)")
            }
            
        } catch {
            print("❌ Error: \(error)")
            throw error
        }
        
        // Cleanup
        try await httpClient.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }
}
