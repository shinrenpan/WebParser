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

// 每次解析的間隔時間, 非必要, default = 2, 需 >= 1
parser.delayTime = 2

// 嘗試解析的次數, 非必要, default = 5, 需 >= 1
parser.retryCount = 5

// WKWebsiteDataStore, 非必要, default = WKWebsiteDataStore.default()
parser.websiteDataStore = ...

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
parser.didFail = { (ParseError) in
    // 失敗時觸發
}
```

爬取成功

```swift
parser.didSuccess = { (T) in
    // 成功時觸發
}
```

其他詳見 Unit test.
