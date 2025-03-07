**[WebParser](https://github.com/shinrenpan/WebParser)**

![](https://img.shields.io/badge/Swift-6-blue) ![](https://img.shields.io/badge/iOS-13.0-blue)

基於 WKWebview + JavaScript 實現網頁爬蟲

### 安裝

使用 SPM.

### 使用

```swift

// 1. 設置 Config

let configuration = ParserConfiguration(
    request: makeRequest(), // 爬取的網址
    windowSize: makeWindowSize(), // WebView 視窗大小, 實際上不可見
    customUserAgent: makeUserAgent(), // 客製化 UserAgent
    retryCount: 10, // 重試次數
    retryDuration: 3, // 重試間隔 (秒)
    javascript: makeJS() // 要執行的 JavaScript
)

// 2. 初始化

let parser = Parser(parserConfiguration: configuration)

// 3. 執行

let result = try await parser.decodeResult(SomeData.self) // 使用定義好的 Decodable 類型

// or

let result = try await parser.anyResult() // 返回 Any
```

### Demo

其他詳見 [Demo](https://github.com/shinrenpan/WebParser/tree/main/Demo)

