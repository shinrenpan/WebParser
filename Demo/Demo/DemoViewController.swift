//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import UIKit
import WebParser

final class DemoViewController: UITableViewController
{
    private let _viewModel = DemoViewModel()
    private let _viewOutlet = DemoViewOutlet()
}

// MARK: - LifeCycle

extension DemoViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        _viewModel.parser.delegate = self
        __reloadItemAddAction()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        if _viewModel.dataSource.isEmpty
        {
            _viewModel.parse()
        }
    }
}

// MARK: - WebParserDelegate

extension DemoViewController: WebParserDelegate
{
    func parserDidStart<T>(_ parser: WebParser<T>) where T: Decodable
    {
        __setupNavigationRightItemWhenParsing()
        _viewModel.cleanDataSource()
        tableView.reloadData()
    }

    func parserDidFinish<T>(_ parser: WebParser<T>, result: T) where T: Decodable
    {
        __setupNavigationRightItemWhenStopParsing()
        if let result = result as? [Comic]
        {
            _viewModel.addComics(result)
            tableView.reloadData()
        }
    }

    func parserDidFail<T>(_ parser: WebParser<T>, error: Error) where T: Decodable
    {
        __setupNavigationRightItemWhenStopParsing()
    }

    func parserDidCancel<T>(_ parser: WebParser<T>) where T: Decodable
    {
        __setupNavigationRightItemWhenStopParsing()
    }
}

// MARK: - UITableViewDataSource

extension DemoViewController
{
    override func tableView(_ tableView: UITableView, numberOfRowsInSection scetion: Int) -> Int
    {
        return _viewModel.dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        let comic = _viewModel.dataSource[indexPath.row]
        cell.textLabel?.text = comic.title
        cell.detailTextLabel?.text = comic.episode
        return cell
    }
}

// MARK: - Private

private extension DemoViewController
{
    final func __reloadItemAddAction()
    {
        _viewOutlet.updateItem.target = self
        _viewOutlet.updateItem.action = #selector(__reloadItemClicked(_:))
    }

    @objc
    final func __reloadItemClicked(_ sedner: UIBarButtonItem)
    {
        _viewModel.parse()
    }

    final func __setupNavigationRightItemWhenParsing()
    {
        navigationItem.rightBarButtonItem = _viewOutlet.loadingItem
    }

    final func __setupNavigationRightItemWhenStopParsing()
    {
        navigationItem.rightBarButtonItem = _viewOutlet.updateItem
    }
}
