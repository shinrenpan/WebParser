//
//  DemoVC.swift
//
//  Created by Shinren Pan on 2024/7/25.
//

import Combine
import UIKit

final class DemoVC: UIViewController {
    let vo = DemoVO()
    let vm = DemoVM()
    let router = DemoRouter()
    var binding: Set<AnyCancellable> = .init()
    lazy var dataSource = makeDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSelf()
        setupBinding()
        setupVO()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        vo.loading.startAnimating()
        vm.doAction(.loadData)
    }
}

// MARK: - Private

private extension DemoVC {
    // MARK: Setup Something

    func setupSelf() {
        view.backgroundColor = vo.mainView.backgroundColor
        router.vc = self
    }

    func setupBinding() {
        vm.$state.receive(on: DispatchQueue.main).sink { [weak self] state in
            guard let self else { return }
            if viewIfLoaded?.window == nil { return }

            switch state {
            case .none:
                stateNone()
            case let .dataLoaded(comics):
                stateDataLoaded(comics: comics)
            case let .dataLoadFail(error):
                stateDataLoadFail(error: error)
            }
        }.store(in: &binding)
    }

    func setupVO() {
        view.addSubview(vo.mainView)

        NSLayoutConstraint.activate([
            vo.mainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            vo.mainView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            vo.mainView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            vo.mainView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    // MARK: - Handle State

    func stateNone() {}
    
    func stateDataLoaded(comics: [DemoModel.Comic]) {
        vo.loading.stopAnimating()
        
        var snapshot = DemoModel.SnapShot()
        snapshot.appendSections([0])
        snapshot.appendItems(comics, toSection: 0)
        dataSource.apply(snapshot)
    }
    
    func stateDataLoadFail(error: Error) {
        vo.loading.stopAnimating()
        print(error)
    }
    
    // MARK: - Make Something
    
    func makeCell() -> DemoModel.CellRegistration {
        .init { cell, indexPath, comic in
            var config = UIListContentConfiguration.cell()
            config.text = comic.title
            cell.contentConfiguration = config
        }
    }
    
    func makeDataSource() -> DemoModel.DataSource {
        let cell = makeCell()
        
        return .init(collectionView: vo.list) { collectionView, indexPath, comic in
            return collectionView.dequeueConfiguredReusableCell(using: cell, for: indexPath, item: comic)
        }
    }
}
