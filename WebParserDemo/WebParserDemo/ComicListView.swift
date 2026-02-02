//
//  ComicListView.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import SwiftUI

/// 顯示最新漫畫更新清單的視圖.
///
/// 此視圖透過 `ComicListViewModel` 與 `WebParser` 框架互動,
/// 展示了包含進度條、錯誤處理以及下拉刷新的完整 UI 流程.
struct ComicListView: View {
  /// 使用 ViewModel 監控資料與狀態變更.
  @State private var viewModel: ComicListViewModel = .init()

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoaderShowing {
          // 狀態一：載入中 - 顯示進度條與百分比
          VStack(spacing: 20) {
            ProgressView(value: viewModel.progress, total: 1.0)
              .progressViewStyle(.linear)
              .padding()
            Text("正在同步漫畫數據... \(Int(viewModel.progress * 100))%")
              .foregroundStyle(.secondary)
          }
        }
        else if let error = viewModel.errorMessage {
          // 狀態二：解析失敗 - 顯示錯誤訊息與重試按鈕
          ContentUnavailableView(
            "解析失敗",
            systemImage: "exclamationmark.triangle",
            description: Text(error),
          )
          .toolbar {
            ToolbarItem(placement: .bottomBar) {
              Button("重試") {
                Task { await viewModel.fetchComics() }
              }
            }
          }
        }
        else {
          // 狀態三：成功載入 - 顯示漫畫列表
          List(viewModel.comics) { comic in
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text(comic.title)
                  .font(.headline)
                  .lineLimit(1)
                Spacer()
                // 顯示相對時間 (例如：3 小時前)
                Text(formatDate(comic.lastUpdate))
                  .font(.caption2)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .background(Color.blue.opacity(0.1))
                  .cornerRadius(4)
              }

              Text("最新更新: \(comic.note)")
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
            .padding(.vertical, 4)
          }
          .listStyle(.plain)
          .refreshable {
            // 支援下拉刷新
            await viewModel.fetchComics()
          }
        }
      }
      .navigationTitle("最新漫畫更新")
      .onAppear {
        // 進入頁面時自動抓取資料
        if viewModel.comics.isEmpty {
          Task { await viewModel.fetchComics() }
        }
      }
    }
  }

  /// 將時間戳記轉換為易讀的相對時間字串.
  /// - Parameter timestamp: Unix 時間戳記.
  /// - Returns: 本地化的相對時間描述 (例如：剛剛, 5 分鐘前).
  private func formatDate(_ timestamp: Double) -> String {
    let date = Date(timeIntervalSince1970: timestamp)
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
  }
}
