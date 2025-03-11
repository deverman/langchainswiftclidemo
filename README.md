# LangChain Swift CLI

A command-line interface demonstrating the use of LangChain Swift with OpenAI's API.

## Features

- Demonstrates basic LangChain Swift setup
- Uses OpenAI's chat completion API
- Implements streaming responses
- Proper async/await implementation
- Proper resource cleanup

## Requirements

- macOS 13.0 or later
- Swift 5.9 or later
- OpenAI API key

## Setup

1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/langchaincli.git
cd langchaincli
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

## Project Structure

- `Sources/main.swift`: Main application code implementing LangChain Swift
- `Package.swift`: Swift package manifest with dependencies
- `.gitignore`: Git ignore file
- `README.md`: This file

## Dependencies

- [LangChain Swift](https://github.com/buhe/langchain-swift): Swift implementation of LangChain
- AsyncHTTPClient: Async HTTP client for Swift

## License

This project is available under the MIT license. 