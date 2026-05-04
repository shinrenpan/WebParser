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

  /// FetchResult 僅被 State.fetchResult 使用，屬 State 的 L2
  enum FetchResult: Sendable {
    case idle
    case loading
    case success(String)
    case failure(String)
  }
}
