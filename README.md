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

初始化 Parser

```swift
let parser = WebParser<[Comic]>()
```

設置設定

```swift
// 要爬取的網址, 必要
parser.parseURL = ...

// 爬取用的 JavaScript, 必要 
parser.javaScript = ...

// 客製化 UserAgent, 非必要
parser.customUserAgent = ...

// 每次解析的間隔時間, default = 2, 需 >= 1
parser.delayTime = 2

// 嘗試解析的次數, default = 5, 需 >= 1
parser.retryCount = 5

// 設置 Delegation
parser.delegate = self
```

開始爬取

```swift
parser.start()
```

取消爬取

```swift
parser.cancel()
```


## Handle ##

使用 Delegation 方式處理.

開始爬取

```swift
func parserDidStart<T>(_ parser: WebParser<T>) where T : Decodable
{
    // parser.start() 觸發
}
```

取消爬取

```swift
func parserDidCancel<T>(_ parser: WebParser<T>) where T : Decodable {
{
    // parser.cancel() 觸發
}
```

爬取失敗

```swift
func parserDidFail<T>(_ parser: WebParser<T>, error: Error) where T: Decodable
{
    // 失敗時觸發
}
```

爬取成功

```swift
func parserDidFinish<T>(_ parser: WebParser<T>, result: T) where T: Decodable
{
    // 成功時觸發
    // 取得正確 Result
    if let result = result as? [Comic]
    {
        
    }
}
```

其他詳見 Unit test.