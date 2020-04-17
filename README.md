# WebParser #

基於 WKWebView 與 JavaScript 組成的 iOS 爬蟲.  

## 使用方法 ##

1. **設置 Decodable model**

```swift
struct Comic: Decodable
{
    private(set) var title: String?
    private(set) var episode: String?
}
```

2. **設置 Parser 設定**

```swift
struct UpdateConfigure: WebParserConfiguration
{
    var url: URL = URL(string: "https://tw.manhuagui.com/update/")!

    var maxRetryCount: Int = 5

    var retryDelay: TimeInterval = 3.0

    var timeout: TimeInterval = 30.0

    var browser: Browser = .iPhone

    var javascript: String = """
    var results = [];
    $('.latest-list > ul > li').each(function(idx, element)
    {
        var comic = {};
        comic.title = $(element).find('.cover').eq(0).attr('title');
        comic.episode = $(element).find('.tt').text();

        results.push(comic);
    });
    results;
    """
}
```

3. **初始化 Parser 並開始使用**

```swift
let parser = WebParser<[Comic]>(configure: UpdateConfigure())

// 開始爬取
parser.start()

// 取消爬取
parser.cancel()
```

## Handle ##

使用 Closure 方式處理.

**處理開始爬取**

```swift
parser.didStart = {
    // parser.start() 觸發
}
```

**處理取消爬取**

```swift
parser.didCancel = {
    // parser.cancel() 觸發
}
```

**處理爬取失敗**

```swift
parser.didFailure = { error: WebParserError in
    // 失敗時觸發
}
```

**處理爬取成功**

```swift
parser.didSuccess = { result: T in
    // 成功時觸發
}
```

> 其他詳見 [Unit test](WebParserTests/WebParserTests.swift)
