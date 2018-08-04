
根據這篇 [網路爬蟲][1], 基於 WKWebView, 實做出可以 model 化的爬蟲 Framework


## Required ##
- Xcode 9.3
- Swift 4.1


## Install ##
Use carthage.


## 使用 ##
以 [網路爬蟲][1] 文章為例:

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
let parser: WebParser = WebParser<[Comic]>()
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
parser.callback = { (result: WebParser<[Comic]>.Result) in
    switch result
    {
        case let .success(comics):
        //do success action

        case let .error(e):
        // do error action
    }
}
```

**步驟 6: 開始爬取**

```swift
parser.parse()
```

[1]: https://shinrenpan.github.io/post/web-parser/
