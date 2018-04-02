Parse website use javascript base on WKWebView.


## Required ##
- Xcode 9.3
- Swift 4.1

> Swift only, not support Objective-C


## Install ##
Use carthage.


## Useage ##

```swift

// 1. Setup your decodable model.
struct MyModel: Decodable
{
    let name: String
    let img: String
}

// 2. Init WebParser.
let parser: WebParser = WebParser<MyModel>()
{ (model: MyModel?, error: Error?) in

}

// 3. Setup parse url.
parser.parseURL = "https://www.someurl.com"

// 4. Setup parse javascript.
parser.javaScript = "some javascript"

// 5. Start parse.
parser.parse()
```
