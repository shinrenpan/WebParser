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
    private lazy var _parser = __initParser()
    private var _dataSource: [Comic]?
}

extension WebParserTests
{
    final func testParser()
    {
        _parser.didSuccess = {
            [weak self] result in
            self?._dataSource = result
            self?._expectation.fulfill()
        }

        _parser.didFail = {
            [weak self] _ in
            self?._expectation.fulfill()
        }

        let JavaScript = __JavaScript()
        _parser.parseUsing(JavaScript: JavaScript)

        wait(for: [_expectation], timeout: _parser.config.timeOut)
        XCTAssertNotNil(_dataSource, "Parser Fail")
    }
}

private extension WebParserTests
{
    final func __JavaScript() -> String
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

    final func __initParser() -> WebParser<[Comic]>
    {
        let url = "https://tw.manhuagui.com/update/"
        let config = WebParserConfiguration(urlString: url)
        return WebParser<[Comic]>(config: config)
    }
}
