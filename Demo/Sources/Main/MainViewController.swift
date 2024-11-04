//
//  MainViewController.swift
//
//  Created by Shinren Pan on 2024/7/25.
//

import Observation
import UIKit

extension Main {
    final class ViewController: UIViewController {
        let vo = ViewOutlet()
        let vm = ViewModel()
        let router = Router()
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
        
        // MARK: - Setup Something

        private func setupSelf() {
            view.backgroundColor = vo.mainView.backgroundColor
            router.vc = self
        }

        private func setupBinding() {
            _ = withObservationTracking {
                vm.state
            } onChange: { [weak self] in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if viewIfLoaded?.window == nil { return }
                    
                    switch vm.state {
                    case .none:
                        stateNone()
                    case let .dataLoaded(response):
                        stateDataLoaded(response: response)
                    case let .dataLoadFail(error):
                        stateDataLoadFail(error: error)
                    }
                    
                    setupBinding()
                }
            }
        }

        private func setupVO() {
            view.addSubview(vo.mainView)

            NSLayoutConstraint.activate([
                vo.mainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                vo.mainView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                vo.mainView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                vo.mainView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        }
        
        // MARK: - Handle State

        private func stateNone() {}
        
        private func stateDataLoaded(response: DataLoadedResponse) {
            vo.loading.stopAnimating()
            
            var snapshot = SnapShot()
            snapshot.appendSections([0])
            snapshot.appendItems(response.comics, toSection: 0)
            dataSource.apply(snapshot)
        }
        
        private func stateDataLoadFail(error: Error) {
            vo.loading.stopAnimating()
            print(error)
        }
        
        // MARK: - Make Something
        
        private func makeCell() -> CellRegistration {
            .init { cell, indexPath, comic in
                var config = UIListContentConfiguration.cell()
                config.text = comic.title
                cell.contentConfiguration = config
            }
        }
        
        private func makeDataSource() -> DataSource {
            let cell = makeCell()
            
            return .init(collectionView: vo.list) { collectionView, indexPath, comic in
                return collectionView.dequeueConfiguredReusableCell(using: cell, for: indexPath, item: comic)
            }
        }
    }
}