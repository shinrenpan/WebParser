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

        _parser.didSuccess = {
            [weak self] (result) in
            self?._dataSource = result
            self?._expectation.fulfill()
        }

        _parser.didFail = {
            [weak self] _ in
            self?._expectation.fulfill()
        }

        _parser.start()

        wait(for: [_expectation], timeout: 12)
        XCTAssertNotNil(_dataSource, "Parser Fail")
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
