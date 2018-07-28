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
struct Comic: Decodable
{
    private(set) var title: String?
    private(set) var episode: String?
}

// 2. Init WebParser.
let parser: WebParser = WebParser<[Comic]>()

// 3. Set parse url.
parser.parseURL = "https://tw.manhuagui.com/update/"

// 4. Set parse javascript.
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

// 5. Set parser callback
parser.callback = { (result: WebParser<[Comic]>.Result) in
	switch result
	{
		case let .success(comics):
			// do success action

		case let .error(e):
			// do error action
    }
}

// 6. Start parse.
parser.parse()
```

Also see [Demo](Demo) project.