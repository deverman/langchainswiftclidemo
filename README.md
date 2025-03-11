# LangChain Swift CLI

A command-line interface demonstrating the use of LangChain Swift with OpenAI's API, featuring agentic AI capabilities.

## Features

- Demonstrates advanced LangChain Swift setup with agents
- Uses OpenAI's chat completion API
- Implements custom tools for time checking and calculations
- Command-line argument parsing
- Proper async/await implementation
- Proper resource cleanup

## Requirements

- macOS 13.0 or later
- Swift 5.9 or later
- OpenAI API key

## Setup

1. Clone the repository
```bash
git clone https://github.com/deverman/langchainswiftclidemo.git
cd langchainswiftclidemo
```

2. Set your OpenAI API key as an environment variable:
```bash
export OPENAI_API_KEY='your-api-key-here'
```

3. Build and run the project:
```bash
swift build
.build/debug/langchainswiftclidemo --query "What time is it?"
```

## Usage

The CLI supports the following options:

```bash
# Basic usage
.build/debug/langchainswiftclidemo --query "What time is it?"

# Enable verbose output (shows available tools)
.build/debug/langchainswiftclidemo --query "Calculate 15 * 24" --verbose

# Combined tool usage example
.build/debug/langchainswiftclidemo --query "What time is it and calculate 15 * 24?"
```

### Available Tools

1. **Time Check Tool (`time_check`)**
   - Gets the current time in HH:mm:ss format
   - Example: "What time is it?"

2. **Calculator Tool (`calculator`)**
   - Performs multiplication calculations
   - Currently supports multiplication operations (e.g., "15 * 24")
   - Example: "Calculate 15 * 24"

## Project Structure

- `Sources/main.swift`: Main application code implementing:
  - Custom Tool protocol
  - TimeCheckTool and CalculatorTool implementations
  - CustomAgent for handling tool execution
  - AsyncParsableCommand for CLI interface
- `Package.swift`: Swift package manifest with dependencies
- `.gitignore`: Git ignore file
- `README.md`: Project documentation
- `LICENSE`: MIT license file

## Dependencies

- [LangChain Swift](https://github.com/buhe/langchain-swift): Swift implementation of LangChain
- [ArgumentParser](https://github.com/apple/swift-argument-parser): Command-line argument parsing
- AsyncHTTPClient: Async HTTP client for Swift
- NIO: SwiftNIO for async networking

## License

This project is available under the MIT license. 