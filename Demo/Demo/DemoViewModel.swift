//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import Foundation
import WebParser

final class DemoViewModel: NSObject
{
    private(set) var dataSource: [Comic] = []
    private(set) lazy var parser: WebParser<[Comic]> = {
        __initParser()
    }()
}

// MARK: - Public

extension DemoViewModel
{
    final func parse()
    {
        parser.start()
    }

    final func cleanDataSource()
    {
        dataSource.removeAll()
    }

    final func addComics(_ comics: [Comic])
    {
        dataSource.append(contentsOf: comics)
    }
}

// MARK: - Private

private extension DemoViewModel
{
    final func __initParser() -> WebParser<[Comic]>
    {
        let url = "https://tw.manhuagui.com/update/"
        let javaScript = """
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

        let result = WebParser<[Comic]>()
        result.parseURL = url
        result.javaScript = javaScript
        return result
    }
}
