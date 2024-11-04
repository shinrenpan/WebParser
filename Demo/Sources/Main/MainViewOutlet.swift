//
//  MainViewOutlet.swift
//
//  Created by Shinren Pan on 2024/7/25.
//

import UIKit

extension Main {
    @MainActor
    final class ViewOutlet {
        let mainView = UIView(frame: .zero)
        let list = UICollectionView(frame: .zero, collectionViewLayout: makeListLayout())
        let loading = UIActivityIndicatorView(style: .large)
        
        init() {
            setupSelf()
            addViews()
        }
        
        // MARK: - Setup Something
        
        func setupSelf() {
            mainView.translatesAutoresizingMaskIntoConstraints = false
            list.translatesAutoresizingMaskIntoConstraints = false
            loading.translatesAutoresizingMaskIntoConstraints = false
            loading.color = .systemBlue
            loading.hidesWhenStopped = true
        }
        
        // MARK: - Add Something
        
        func addViews() {
            mainView.addSubview(list)
            mainView.addSubview(loading)
            
            NSLayoutConstraint.activate([
                list.topAnchor.constraint(equalTo: mainView.topAnchor),
                list.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
                list.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
                list.bottomAnchor.constraint(equalTo: mainView.bottomAnchor),
                
                loading.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
                loading.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
            ])
        }
        
        // MARK: - Make Something
        
        static func makeListLayout() -> UICollectionViewCompositionalLayout {
            let config = UICollectionLayoutListConfiguration(appearance: .plain)
            
            return UICollectionViewCompositionalLayout.list(using: config)
        }
    }
}
