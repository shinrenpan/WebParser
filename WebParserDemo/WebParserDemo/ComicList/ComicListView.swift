//
//  ComicListView.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import SwiftUI

struct ComicListView: View {
  // MARK: - ViewModel

  let viewModel: ComicListViewModel

  // MARK: - Body

  var body: some View {
    Group {
      switch viewModel.state.loadingState {
      case let .loading(progress) where viewModel.state.comics.isEmpty:
        LoadingSection(progress: progress)

      case let .failure(message):
        ErrorSection(message: message) { action in
          switch action {
          case .retryDidTap:
            Task { await viewModel.doAction(.view(.retryDidTap)) }
          }
        }

      default:
        ListSection(comics: viewModel.state.comics)
          .refreshable {
            await viewModel.doAction(.view(.refreshDidTrigger))
          }
      }
    }
    .navigationTitle("最新漫畫更新")
    .task {
      await viewModel.doAction(.view(.onAppear))
    }
  }
}

private extension ComicListView {
  struct LoadingSection: View {
    let progress: Double

    var body: some View {
      VStack(spacing: 20) {
        ProgressView(value: progress, total: 1.0)
          .progressViewStyle(.linear)
          .padding()
        Text("正在同步漫畫數據... \(Int(progress * 100))%")
          .foregroundStyle(.secondary)
      }
    }
  }
}

private extension ComicListView {
  struct ErrorSection: View {
    enum Action: Sendable {
      case retryDidTap
    }

    let message: String
    let send: (Action) -> Void

    var body: some View {
      ContentUnavailableView(
        "解析失敗",
        systemImage: "exclamationmark.triangle",
        description: Text(message),
      )
      .toolbar {
        ToolbarItem(placement: .bottomBar) {
          Button("重試") {
            send(.retryDidTap)
          }
        }
      }
    }
  }
}

private extension ComicListView {
  struct ListSection: View {
    let comics: [ComicListViewModel.Comic]

    var body: some View {
      List(comics) { comic in
        ListRow(comic: comic)
      }
      .listStyle(.plain)
    }
  }

  struct ListRow: View {
    let comic: ComicListViewModel.Comic

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(comic.title)
            .font(.headline)
            .lineLimit(1)
          Spacer()
          Text(formatDate(comic.lastUpdate))
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        Text("最新更新: \(comic.note)")
          .font(.subheadline)
          .foregroundStyle(.blue)
      }
      .padding(.vertical, 4)
    }

    private func formatDate(_ timestamp: Double) -> String {
      let date = Date(timeIntervalSince1970: timestamp)
      return Self.relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// formatter 建立成本高，使用 static 確保整個 View 類型只建立一次
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .full
      return formatter
    }()
  }
}
