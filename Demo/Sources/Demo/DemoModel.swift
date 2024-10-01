//
//  DemoModel.swift
//
//  Created by Shinren Pan on 2024/7/25.
//

import UIKit

enum DemoModel {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, Comic>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Int, Comic>
    typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Comic>
}

// MARK: - Action

extension DemoModel {
    enum Action {
        case loadData
    }
}

// MARK: - State

extension DemoModel {
    enum State {
        case none
        case dataLoaded(comics: [Comic])
        case dataLoadFail(error: Error)
    }
}

// MARK: - Other Model for DisplayModel

extension DemoModel {
    struct Comic: Hashable, Decodable {
        let id: String
        let title: String
        
        enum CodingKeys: CodingKey {
            case id
            case title
        }
        
        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<DemoModel.Comic.CodingKeys> = try decoder.container(keyedBy: DemoModel.Comic.CodingKeys.self)
            self.id = UUID().uuidString
            self.title = try container.decode(String.self, forKey: DemoModel.Comic.CodingKeys.title)
        }
    }
}
