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
swift run
```

## Usage

The CLI supports various commands and options:

```bash
# Basic usage
swift run langchainswiftclidemo --query "What time is it?"

# Enable verbose output
swift run langchainswiftclidemo --query "Calculate 15 * 24" --verbose

# Example queries
swift run langchainswiftclidemo --query "What's the current time and calculate 42 + 7?"
swift run langchainswiftclidemo --query "Tell me the time and multiply 13 by 5"
```

### Available Tools

1. **Time Check Tool (`current_time`)**
   - Gets the current date and time
   - Example: "What time is it?"

2. **Calculator Tool (`calculator`)**
   - Performs basic mathematical calculations
   - Example: "Calculate 15 * 24"

## Project Structure

- `Sources/main.swift`: Main application code implementing LangChain Swift with agents and tools
- `Package.swift`: Swift package manifest with dependencies
- `.gitignore`: Git ignore file
- `README.md`: This file

## Dependencies

- [LangChain Swift](https://github.com/buhe/langchain-swift): Swift implementation of LangChain
- [ArgumentParser](https://github.com/apple/swift-argument-parser): Command-line argument parsing
- AsyncHTTPClient: Async HTTP client for Swift

## License

This project is available under the MIT license. 