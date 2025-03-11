// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import LangChain
import NIOCore
import NIOPosix
import AsyncHTTPClient

// Replace with your OpenAI API key
let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
if openAIKey.isEmpty {
    print("Please set the OPENAI_API_KEY environment variable")
    exit(1)
}

// Set up LangChain configuration
LC.initSet([
    "OPENAI_API_KEY": openAIKey
])

// Function to run the chat
func runChat() async {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let httpClient = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
    
    let llm = ChatOpenAI(httpClient: httpClient, temperature: 0.7)
    if let answer = await llm.generate(text: "What is the best way to learn Japaneses?") {
        print("\nAssistant's response:")
        do {
            for try await chunk in answer.getGeneration()! {
                if let message = chunk {
                    print(message, terminator: "")
                }
            }
            print("\n")
        } catch {
            print("Error during streaming: \(error)")
        }
    }
    
    // Properly shutdown the clients
    try? await httpClient.shutdown()
    try? await eventLoopGroup.shutdownGracefully()
}

// Run the chat
Task {
    await runChat()
    exit(0)
}

// Keep the main thread running
RunLoop.main.run()
