//
//  DemoModels.swift
//
//  Created by Shinren Pan on 2024/7/25.
//

import UIKit

enum DemoModels {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, Comic>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Int, Comic>
    typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Comic>
}

// MARK: - Action

extension DemoModels {
    enum Action {
        case loadData
    }
}

// MARK: - State

extension DemoModels {
    enum State {
        case none
        case dataLoaded(comics: [Comic])
        case dataLoadFail(error: Error)
    }
}

// MARK: - Other Model for DisplayModel

extension DemoModels {
    struct Comic: Hashable, Decodable {
        let id: String
        let title: String
        
        enum CodingKeys: CodingKey {
            case id
            case title
        }
        
        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<DemoModels.Comic.CodingKeys> = try decoder.container(keyedBy: DemoModels.Comic.CodingKeys.self)
            self.id = UUID().uuidString
            self.title = try container.decode(String.self, forKey: DemoModels.Comic.CodingKeys.title)
        }
    }
}

// MARK: - Display Model for ViewModel

extension DemoModels {
    final class DisplayModel {}
}
