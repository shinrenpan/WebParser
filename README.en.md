# WebParser 🚀

**English** | [中文](README.md)

![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Build Status](https://github.com/shinrenpan/WebParser/actions/workflows/test.yml/badge.svg)

A modern Swift web-parsing framework built on WebKit off-screen rendering. Designed for complex pages that require JavaScript execution, smart polling, and dynamic DOM loading.

## ✨ Features

- **Native Swift 6 support**: fully `async/await`-based, optimized for concurrency safety.
- **Dynamic page rendering**: a built-in `WKWebView` engine runs custom JavaScript, handling SPAs and sites with encrypted data with ease.
- **Type-safe mapping (Mapper)**:
  - `WebParserJSJSONMapper`: decodes JSON returned by JS directly into a Swift `Decodable` model.
  - `WebParserRegexMapper`: extracts content of any type from the raw data via a custom closure — not limited to `Codable`.
- **Smart progress monitoring**: track page-load and parsing state changes in real time via `WebParserProgressDelegate`.
- **Performance**: block media resources (Block Media) to significantly speed up rendering and save bandwidth.
- **Developer friendly**: Swift `#"""` raw-string support keeps JavaScript scripts free of escaping headaches.

## 🗂️ Demo Project Setup

The Demo project is managed with [XcodeGen](https://github.com/yonaskolb/XcodeGen); the `xcodeproj` is not tracked in version control.

```bash
brew install xcodegen
cd WebParserDemo && xcodegen generate
```

Then open `WebParser.xcworkspace`.

## 🛠️ Installation

Add it to your project via **Swift Package Manager**:

```swift
dependencies: [
    .package(url: "https://github.com/shinrenpan/WebParser.git", from: "1.0.0")
]
```

## 🚀 Quick Start

`WebParser` decides its parsing logic through different `Mapper`s; pick one based on the type of data the page returns.

### 1. Using `WebParserJSJSONMapper` (recommended)

When your `executionJS` returns a JavaScript object or array, this is the most efficient path. The engine handles serialization automatically — you only need to define a `Decodable` model.

```swift
// Define the model
struct Comic: Decodable {
  let title: String
  let updateDate: String
}

// Run the parse
let results = try await parser.parse(
  with: config,
  mapper: WebParserJSJSONMapper<[Comic]>()
)
print("Fetched \(results.count) comics")
```

### 2. Using `WebParserRegexMapper`

Use this when you need to extract specific content from the returned raw string with custom logic.

```swift
let config = WebParserConfig(
  url: url,
  executionJS: "document.title"
)

let webTitle = try await parser.parse(
  with: config,
  mapper: WebParserRegexMapper<String> { data in
    let rawString = String(data: data, encoding: .utf8) ?? ""
    // Trim quotes that JS may include around a returned string
    return rawString.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
  }
)
print("Page title is: \(webTitle)")
```

## 🧩 Advanced Usage

### Observing parse state

Make your ViewModel conform to `WebParserProgressDelegate`:

```swift
func webParser(_ parser: WebParser, didUpdateState state: WebParserState) {
  if case let .loading(progress) = state {
    self.uiProgress = progress
  }
}
```

## 🎨 Code Style

- **Indentation**: 2 spaces.
- **Naming**: acronyms in all caps (e.g. `URL`, `ID`, `JS`, `JSON`).
- **Swift 6 compatibility**: optimized for Swift 6.2 syntax; passes all Strict Concurrency checks.
- **Trailing commas**: always add a trailing comma at the end of collection literals for cleaner Git diffs.

If you submit a Pull Request, please make sure you have run `swiftformat .`.

## 🧪 Testing

This project fully adopts the **Swift Testing** framework to ensure the stability of the core logic and WebKit rendering.

```bash
swift test --parallel
```

---

Released under the MIT License by Joe Pan.
