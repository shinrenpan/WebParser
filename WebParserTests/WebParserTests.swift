//
//  Copyright (c) 2019年 shinren.pan@gmail.com All rights reserved.
//

import WebParser
import XCTest

struct Comic: Decodable
{
    private(set) var title: String?
    private(set) var episode: String?
}

class WebParserTests: XCTestCase
{
    private var _expectation = XCTestExpectation(description: "TestParser")
    private var _parser = WebParser<[Comic]>()
    private var _dataSource: [Comic]?
}

extension WebParserTests
{
    final func testParser()
    {
        _parser.parseURL = __parserURL()
        _parser.javaScript = __javaScript()
        _parser.customUserAgent = "iOS"
        _parser.delayTime = 2
        _parser.retryCount = 5
        _parser.delegate = self
        _parser.start()

        wait(for: [_expectation], timeout: 12)
        XCTAssertNotNil(_dataSource, "Parser Fail")
    }
}

extension WebParserTests: WebParserDelegate
{
    func parserDidFinish<T>(_ parser: WebParser<T>, result: T) where T: Decodable
    {
        if let result = result as? [Comic], result.count > 0
        {
            _dataSource = result
        }

        _expectation.fulfill()
    }

    func parserDidFail<T>(_ parser: WebParser<T>, error: Error) where T: Decodable
    {
        _expectation.fulfill()
    }
}

private extension WebParserTests
{
    final func __parserURL() -> String
    {
        return "https://tw.manhuagui.com/update/"
    }

    final func __javaScript() -> String
    {
        return """
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
}
