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

  /// LoadingState 僅被 State.loadingState 使用，屬 State 的 L2
  enum LoadingState: Sendable {
    /// 初始或已完成狀態.
    case idle
    /// 載入中，附帶進度值 0.0–1.0.
    case loading(Double)
    /// 載入成功.
    case success
    /// 載入失敗，附帶錯誤訊息.
    case failure(String)
  }
}

// MARK: - Domain Models

extension ComicListViewModel {
  /// 描述漫畫更新資訊的領域模型.
  struct Comic: Identifiable, Sendable, Decodable {
    let id: String
    let title: String
    let cover: String
    let note: String
    let lastUpdate: Double
  }
}
