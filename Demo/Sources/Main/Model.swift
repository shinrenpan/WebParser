//
//  Model.swift
//
//  Created by Shinren Pan on 2024/7/25.
//

import UIKit

typealias DataSource = UICollectionViewDiffableDataSource<Int, DisplayComic>
typealias SnapShot = NSDiffableDataSourceSnapshot<Int, DisplayComic>
typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, DisplayComic>

enum Action {
    case loadData
}

enum State {
    case none
    case dataLoaded(response: DataLoadedResponse)
    case dataLoadFail(error: Error)
}

struct DataLoadedResponse {
    let comics: [DisplayComic]
}

struct DisplayComic: Hashable, Decodable {
    let id: String
    let title: String
    
    enum CodingKeys: CodingKey {
        case id
        case title
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys.self)
        self.id = UUID().uuidString
        self.title = try container.decode(String.self, forKey: Self.CodingKeys.title)
    }
}
