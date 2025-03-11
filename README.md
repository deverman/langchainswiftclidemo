# LangChain Swift CLI Tutorial

A beginner-friendly tutorial demonstrating how to build a simple AI assistant using LangChain Swift. This example shows how to create custom tools and integrate them with OpenAI's API.

## What You'll Learn

- How to create custom tools in LangChain Swift
- How to build a simple command-line interface
- How to handle asynchronous operations in Swift
- Basic error handling and resource management

## Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- OpenAI API key (get one at https://platform.openai.com)

## Project Structure

```
.
├── Sources/
│   └── main.swift      # Main implementation
├── Package.swift       # Dependencies
└── README.md          # This file
```

## Tutorial Steps

### 1. Setup Your Environment

1. Clone the repository:
```bash
git clone https://github.com/deverman/langchainswiftclidemo.git
cd langchainswiftclidemo
```

2. Set your OpenAI API key:
```bash
export OPENAI_API_KEY='your-api-key-here'
```

### 2. Understanding the Code

The project consists of three main parts:

1. **Tool Protocol**: Defines what a tool can do
```swift
protocol Tool {
    func name() -> String
    func description() -> String
    func call(_ input: String) async throws -> String
}
```

2. **Custom Tools**: Two example tools
   - `TimeCheckTool`: Returns the current time
   - `CalculatorTool`: Performs multiplication

3. **Assistant**: Processes queries using the tools

### 3. Build and Run

1. Build the project:
```bash
swift build
```

2. Try different examples:
```bash
# Get the current time
.build/debug/langchainswiftclidemo --query "What time is it?"

# Do a calculation
.build/debug/langchainswiftclidemo --query "Calculate 5 * 3"

# Try both tools at once
.build/debug/langchainswiftclidemo --query "What time is it and calculate 15 * 24?"

# See available tools
.build/debug/langchainswiftclidemo --verbose
```

## How It Works

1. The program starts by checking for your OpenAI API key
2. It creates instances of our custom tools
3. When you make a query:
   - Each tool attempts to process your input
   - Results from all tools are combined
   - The response is formatted and displayed

## Creating Your Own Tools

To add a new tool:

1. Create a new class that implements the `Tool` protocol
2. Add your tool's logic in the `call` method
3. Add your tool to the `tools` array in `main.swift`

Example:
```swift
final class MyNewTool: Tool {
    func name() -> String {
        return "my_tool"
    }
    
    func description() -> String {
        return "Description of what my tool does"
    }
    
    func call(_ input: String) async throws -> String {
        // Your tool's logic here
        return "Result"
    }
}
```

## Dependencies

- [LangChain Swift](https://github.com/buhe/langchain-swift): Core LangChain functionality
- [ArgumentParser](https://github.com/apple/swift-argument-parser): Command-line interface
- AsyncHTTPClient & NIO: Networking support

## Common Issues

1. **API Key Error**: Make sure your OpenAI API key is set correctly
2. **Build Errors**: Ensure you have Swift 5.9 or later installed
3. **Runtime Errors**: Check your query format matches the tool's expectations

## Next Steps

1. Try adding your own custom tool
2. Modify the calculator to support more operations
3. Experiment with different LangChain features

## License

This project is available under the MIT license. 