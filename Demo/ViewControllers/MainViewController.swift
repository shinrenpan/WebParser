//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import UIKit
import WebParser

final class MainViewController: UITableViewController
{
    @IBOutlet private var __reloadItem: UIBarButtonItem!

    private var __dataSource: [Comic]?
    private let __parser: WebParser = WebParser<[Comic]>()
}

// MARK: - LifeCycle

extension MainViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = __reloadItem
        __setupParser()
        __setupParserCallback()
    }
}

extension MainViewController
{
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        if __dataSource == nil
        {
            __reloadItemClicked(nil)
        }
    }
}

// MARK: - UITableViewDataSource

extension MainViewController
{
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        else
        {
            fatalError("Can't find cell")
        }

        if let comic: Comic = __dataSource?[indexPath.row]
        {
            cell.textLabel?.text = comic.title
            cell.detailTextLabel?.text = comic.episode
        }

        return cell
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int
    {
        return __dataSource?.count ?? 0
    }
}

// MARK: - IBAction

private extension MainViewController
{
    @IBAction func __reloadItemClicked(_: UIBarButtonItem?)
    {
        navigationItem.rightBarButtonItem = __loadingItem()
        __dataSource = nil
        tableView.reloadData()

        __parser.parse()
    }
}

// MARK: - Private

private extension MainViewController
{
    func __setupParser()
    {
        let javaScript: String = """
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

        __parser.javaScript = javaScript
        __parser.parseURL = "https://tw.manhuagui.com/update/"
    }
}

private extension MainViewController
{
    func __setupParserCallback()
    {
        __parser.callback = { [weak self] (result: WebParser<[Comic]>.Result) in
            guard
                let `self`: MainViewController = self
            else
            {
                return
            }

            self.navigationItem.rightBarButtonItem = self.__reloadItem

            switch result
            {
                case let .success(comics):
                    self.__dataSource = comics
                    self.tableView.reloadData()

                case let .error(e):
                    print(e)
            }
        }
    }
}

private extension MainViewController
{
    func __loadingItem() -> UIBarButtonItem
    {
        let loadingView: UIActivityIndicatorView =
            UIActivityIndicatorView(activityIndicatorStyle: .gray)

        loadingView.startAnimating()

        return UIBarButtonItem(customView: loadingView)
    }
}
