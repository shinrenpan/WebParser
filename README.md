# WabParser
基於 WKWebView 的 iOS 網路爬蟲.  
使用方式請參考以下說明或是 [Demo](Demo).


## 需求 ##
- Swift 4.2 以上.
- iOS 9.0 以上.


## 安裝 ##
Use [Carthage](https://github.com/Carthage/Carthage).


## 使用 ##

**步驟 1: 設置 Model**

```swift
struct Comic: Decodable
{
    private(set) var title: String?
    private(set) var episode: String?
}
```

**步驟 2: 初始化 WebParser**

```swift
var parser: WebParser = WebParser<[Comic]>()
```

**步驟 3: 設置爬取網址**

```swift
parser.parseURL = "https://tw.manhuagui.com/update/"
```

**步驟 4: 設置解析 JavaScript**

```swift
parser.javaScript = """
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
```

**步驟 5: 設置返回 Callback**

```swift
parser.callback = { [weak self] status in
    switch status
    {
        case .none:
            // 初始狀態, 或是 restart 會觸發
        case .start:
            // 開始爬取
        case .cancel:
            // 已取消爬取
        case .error:
           // 爬取失敗
        case let .success(result):
           // 爬取成功, 以例子來說 result == [Comic]
    }
}
```

**步驟 5.5: 設置自定義 UserAgent**

```swift
parser.customUserAgent = "..."
```

**步驟 6: 執行**

- 開始爬取

```swift 
parser.start()
```

- 重新爬取

```swift
parser.restart()
```

- 取消爬取

```swift
parser.cancel()
```

> 如果執行過 start(), 或是 cancel(), 要再次爬取一定要使用 **restart()**.  
> 或是永遠使用 restart() 代替 start()