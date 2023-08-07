# WebParser #

基於 WKWebView 與 Javascript 組成的 iOS 網頁爬蟲.  
iOS >= 13.0, swift >= 5.8

[Demo](https://github.com/shinrenpan/WebParser_Demo)

## 使用方法 ##

1. **設置 Decodable model**

```swift
struct Comic: Decodable {
    let title: String
    let detailURI: String
}
```

2. **設置 Parser 設定**

```swift
let javascript = """
var results = [];
var list = $('.latest-list > ul > li');
list.each(function() {
var comic = new Object();
comic.title = $(this).find('a').eq(0).attr('title');
comic.detailURI = $(this).find('a').eq(0).attr('href');
results.push(comic);
});
results;
"""
    
let configure = Configuration(
    uri: "https://www.manhuagui.com/update/",
    retryInterval: 1,
    retryCount: 15,
    userAgent: .safari,
    javascript: javascript
)
```

3. **初始化 Parser 並開始爬取**

```swift
let parser = Parser(configuration: configure)
let result = try await parser.parse([Comic].self)
```
