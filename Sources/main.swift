// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import LangChain
import ArgumentParser
import AsyncHTTPClient
import NIOCore

// Custom tool for getting the current time
struct TimeCheckTool: Tool {
    let name = "current_time"
    let description = "Get the current time and date"
    
    func run(args: String) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        return formatter.string(from: Date())
    }
}

// Custom tool for basic calculations
struct CalculatorTool: Tool {
    let name = "calculator"
    let description = "Perform basic mathematical calculations"
    
    func run(args: String) async throws -> String {
        // Simple expression evaluator (for demo purposes)
        let expr = NSExpression(format: args)
        if let result = expr.expressionValue(with: nil, context: nil) as? NSNumber {
            return "\(result)"
        }
        return "Could not evaluate expression"
    }
}

@main
struct AIAssistant: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "ai-assistant",
        abstract: "An AI assistant that can perform various tasks",
        discussion: "Uses LangChain Swift to create an agentic AI that can handle multiple tools."
    )
    
    @Option(name: .long, help: "The question or task for the AI assistant")
    var query: String
    
    @Flag(name: .long, help: "Enable verbose output")
    var verbose: Bool = false
    
    mutating func run() async throws {
        // Initialize HTTP client
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
        
        defer {
            try? httpClient.syncShutdown()
        }
        
        // Initialize the LLM
        let llm = ChatOpenAI(httpClient: httpClient, temperature: 0.7)
        
        // Create tools
        let tools: [any Tool] = [
            TimeCheckTool(),
            CalculatorTool()
        ]
        
        // Initialize the agent
        let agent = try await initialize_agent(llm: llm, tools: tools)
        
        print("🤖 Processing your request: \(query)")
        if verbose {
            print("🛠️ Available tools: \(tools.map { $0.name }.joined(separator: ", "))")
        }
        
        // Run the agent
        let result = try await agent.run(args: query)
        
        // Process the result
        switch result {
        case .str(let response):
            print("\n✨ AI Assistant's Response:")
            print(response)
        default:
            print("❌ Unexpected response format")
        }
    }
}

// Keep the main thread running
RunLoop.main.run()
