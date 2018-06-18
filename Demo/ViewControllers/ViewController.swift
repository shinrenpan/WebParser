//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import UIKit
import WebParser

final class ViewController: UITableViewController
{
    @IBOutlet private var _reloadItem: UIBarButtonItem!

    private var _dataSource: [Comic]?
    private var _parser: WebParser = WebParser<[Comic]>()
}

// MARK: - LifeCycle

extension ViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = _reloadItem
        __setupParser()
        __setupParserCallback()
    }
}

extension ViewController
{
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        if _dataSource == nil
        {
            __reloadItemClicked(nil)
        }
    }
}

// MARK: - UITableViewDataSource

extension ViewController
{
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        else
        {
            fatalError("Can't find cell")
        }

        if let comic: Comic = _dataSource?[indexPath.row]
        {
            cell.textLabel?.text = comic.title
            cell.detailTextLabel?.text = comic.episode
        }

        return cell
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int
    {
        return _dataSource?.count ?? 0
    }
}

// MARK: - IBAction

private extension ViewController
{
    @IBAction private func __reloadItemClicked(_: UIBarButtonItem?)
    {
        navigationItem.rightBarButtonItem = __loadingItem()
        _dataSource = nil
        tableView.reloadData()

        _parser.parse()
    }
}

// MARK: - Private

private extension ViewController
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

        _parser.javaScript = javaScript
        _parser.parseURL = "https://tw.manhuagui.com/update/"
    }
}

private extension ViewController
{
    func __setupParserCallback()
    {
        _parser.callback = { [weak self] (results: WebParser<[Comic]>.Result) in
            guard
                let `self`: ViewController = self
            else
            {
                return
            }

            self.navigationItem.rightBarButtonItem = self._reloadItem

            do
            {
                self._dataSource = try results()
                self.tableView.reloadData()
            }
            catch let error
            {
                print(error)
            }
        }
    }
}

private extension ViewController
{
    func __loadingItem() -> UIBarButtonItem
    {
        let loadingView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingView.startAnimating()

        return UIBarButtonItem(customView: loadingView)
    }
}
