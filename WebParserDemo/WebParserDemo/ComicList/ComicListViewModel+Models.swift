//
//  ComicListViewModel+Models.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation

// MARK: - State

extension ComicListViewModel {
  struct State: Sendable {
    var comics: [Comic] = []
    var loadingState: LoadingState = .idle
  }

  enum LoadingState: Sendable {
    case idle
    case loading(Double)
    case success
    case failure(String)
  }
}

// MARK: - Domain Models

extension ComicListViewModel {
  struct Comic: Identifiable, Sendable, Decodable {
    let id: String
    let title: String
    let cover: String
    let note: String
    let lastUpdate: Double
  }
}
