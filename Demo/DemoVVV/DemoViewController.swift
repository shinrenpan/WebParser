//
//  Copyright (c) 2018年 shinren.pan@gmail.com All rights reserved.
//

import UIKit
import WebParser

final class DemoViewController: UITableViewController
{
    private let _viewModel = DemoViewModel()
    private let _viewOutlet = DemoViewOutlet()
    private var _parserListener: NSKeyValueObservation?
}

// MARK: - LifeCycle

extension DemoViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        __setupParserListener()
        __reloadItemAddAction()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        if _viewModel.dataSource.isEmpty
        {
            _viewModel.parser()
        }
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
    final func __setupParserListener()
    {
        _parserListener = _viewModel.observe(\DemoViewModel.parserStatus)
        { [weak self] _, _ in
            guard let self = self else
            {
                return
            }

            self.__handleParserStatus()
        }
    }

    final func __handleParserStatus()
    {
        switch _viewModel.parserStatus
        {
            case .start:
                navigationItem.rightBarButtonItem = _viewOutlet.loadingItem
            case .success:
                tableView.reloadData()
                fallthrough
            default:
                navigationItem.rightBarButtonItem = _viewOutlet.updateItem
        }
    }

    final func __reloadItemAddAction()
    {
        _viewOutlet.updateItem.target = self
        _viewOutlet.updateItem.action = #selector(__reloadItemClicked(_:))
    }

    @objc
    final func __reloadItemClicked(_ sedner: UIBarButtonItem)
    {
        _viewModel.parser()
    }
}
