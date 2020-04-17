//
// Copyright (c) 2020 shinren.pan@gmail.com All rights reserved.
//

import WebParser
import XCTest

struct Comic: Decodable
{
    let title: String?
    let episode: String?
}

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

class WebParserTests: XCTestCase
{
    private var _expectation = XCTestExpectation(description: "TestParser")
    private lazy var _parser = WebParser<[Comic]>(configure: UpdateConfigure())
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

        _parser.didFailure = {
            [weak self] _ in
            self?._expectation.fulfill()
        }

        _parser.start()

        wait(for: [_expectation], timeout: 30)
        XCTAssertNotNil(_dataSource, "Parser Fail")
    }
}
