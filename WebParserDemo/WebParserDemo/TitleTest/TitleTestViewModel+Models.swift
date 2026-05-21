//
//  TitleTestViewModel+Models.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation

// MARK: - State

extension TitleTestViewModel {
  struct State: Sendable {
    var urlString: String = "https://www.apple.com/tw/"
    var fetchResult: FetchResult = .idle
  }

  enum FetchResult: Sendable {
    case idle
    case loading
    case success(String)
    case failure(String)
  }
}
