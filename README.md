# WebParser #

基於 WKWebView 與 JavaScript 組成的爬蟲.  


## 使用方法 ##


設置 Decodable model

```swift
struct Comic: Decodable
{
    private(set) var title: String?
    private(set) var episode: String?
}
```

初始化 Parser 與設置
```swift
let config = WebParserConfiguration(
    delayTime: 2.0, // 每個 Retry 的間隔, Default = 2.0
    retryCount: 5,  // Retry 的次數, Default = 5
    customUserAgent: "iOS", // 自定義 User-Agent, Default = nil
    urlString: "https://someurl" // 要爬取的 URL String
)

let parser = WebParser<[Comic]>(config: config)
```

開始使用 JavaScript 爬取

```swift
let JavaScript = "Some JavaScript"
parser.parseUsing(JavaScript: JavaScript)
```

取消爬取

```swift
parser.cancel()
```


## Handle ##

使用 Closure 方式處理.

開始爬取

```swift
parser.didStart = {
    // parser.start() 觸發
}
```

取消爬取

```swift
parser.didCancel = {
    // parser.cancel() 觸發
}
```

爬取失敗

```swift
parser.didFail = { error: WebParserError in
    // 失敗時觸發
}
```

爬取成功

```swift
parser.didSuccess = { result: T in
    // 成功時觸發
}
```

其他詳見 Unit test.
