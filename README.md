# LangChain & LangGraph Swift Tutorial

A comprehensive tutorial demonstrating how to build an AI assistant using LangChain Swift and LangGraph. This example shows how to create a workflow-based AI application that combines custom tools with OpenAI's API.

## What You'll Learn

- How to use LangChain Swift for building AI applications
- How to create and manage workflows with LangGraph
- How to create custom tools and integrate them with LangChain
- How to build a command-line interface for AI applications
- How to handle state management in AI workflows
- Best practices for error handling and resource management

## Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- OpenAI API key (get one at https://platform.openai.com)

## Project Structure

```
.
├── Sources/
│   └── main.swift      # Main implementation with LangChain and LangGraph integration
├── Package.swift       # Dependencies
└── README.md          # This file
```

## Architecture Overview

The project demonstrates a modern agentic AI architecture with these key components:

1. **State Management** (`AssistantState`)
   - Manages workflow state using LangGraph channels
   - Tracks messages, tool executions, and completion status
   - Provides type-safe access to state data

2. **Tool System**
   - Defines a `Tool` protocol for creating custom tools
   - Each tool has a name, description, and execution logic
   - Tools are automatically discovered by the LLM

3. **Query Processing**
   - Uses LangChain for LLM integration
   - Implements tool selection and execution
   - Handles resource management and cleanup

4. **Command Line Interface**
   - Built with ArgumentParser
   - Supports query execution and verbose mode
   - Provides clear error messages

## Adding Your Own Tools

To add a new tool to the system:

1. Create a new class implementing the `Tool` protocol:
```swift
class MyNewTool: Tool {
    func name() -> String {
        return "my_tool_name" // The name the LLM will use to identify this tool
    }
    
    func description() -> String {
        return "A clear description of what this tool does and how to use it"
    }
    
    func run(_ input: String) async throws -> String {
        // Your tool's logic here
        // Process the input and return a result
        return "Result"
    }
}
```

2. Add your tool to the tools array in `AIAssistant.run()`:
```swift
let tools: [any Tool] = [
    TimeCheckTool(),
    CalculatorTool(),
    MyNewTool()  // Add your new tool here
]
```

The LLM will automatically discover your tool and use it when appropriate based on its name and description.

### Tool Design Best Practices

1. **Clear Names**: Use descriptive names that clearly indicate the tool's purpose
2. **Detailed Descriptions**: Provide clear descriptions that help the LLM understand when to use the tool
3. **Input Validation**: Implement robust input validation in the `run` method
4. **Error Handling**: Use clear error messages that help diagnose issues
5. **Resource Management**: Clean up any resources your tool uses

## Running the Application

1. Set up your environment:
```bash
export OPENAI_API_KEY='your-api-key-here'
```

2. Build the project:
```bash
swift build
```

3. Try different examples:
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

## Error Handling

The system implements several layers of error handling:

1. **Tool-level errors**: Each tool implements its own error handling
2. **Query processing errors**: The `QueryProcessor` handles LLM and execution errors
3. **Resource management**: Automatic cleanup of HTTP clients and event loops
4. **Input validation**: Command-line argument validation

## Resource Management

The system automatically manages:
- HTTP client lifecycle
- Event loop groups
- Tool resources
- Memory cleanup

## Contributing

We welcome contributions! Please see our contributing guidelines for details.

## License

This project is available under the MIT license. 