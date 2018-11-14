//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import Foundation
import WebParser

final class DemoViewModel: NSObject
{
    @objc private(set) dynamic var parserStatus: ParserStatus = .none
    private(set) var dataSource: [Comic] = []
    private var _parser = WebParser<[Comic]>()

    override init()
    {
        super.init()
        __setupParserURL()
        __setupParserJavascript()
        __setupParserCallback()
    }
}

// MARK: - Enum

extension DemoViewModel
{
    @objc enum ParserStatus: Int
    {
        case none
        case start
        case success
        case cancel
        case error
    }
}

// MARK: - Public

extension DemoViewModel
{
    final func parser()
    {
        _parser.restart()
    }
}

// MARK: - Private

private extension DemoViewModel
{
    final func __setupParserURL()
    {
        _parser.parseURL = "https://tw.manhuagui.com/update/"
    }

    final func __setupParserJavascript()
    {
        _parser.javaScript = """
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

    final func __setupParserCallback()
    {
        _parser.callback = { [weak self] status in
            guard let self = self else
            {
                return
            }

            self.__handelParser(status: status)
        }
    }

    final func __handelParser(status: WebParser<[Comic]>.ParserStatus)
    {
        switch status
        {
            case .none:
                parserStatus = .none
            case .start:
                parserStatus = .start
            case .cancel:
                parserStatus = .cancel
            case .error:
                parserStatus = .error
            case let .success(result):
                dataSource = result
                parserStatus = .success
        }
    }
}
