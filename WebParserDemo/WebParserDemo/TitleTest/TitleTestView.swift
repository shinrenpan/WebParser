//
//  TitleTestView.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import SwiftUI

struct TitleTestView: View {
  let viewModel: TitleTestViewModel

  // MARK: - Body

  var body: some View {
    @Bindable var viewModel = viewModel

    Form {
      URLInputSection(
        urlString: $viewModel.state.urlString,
        isLoading: {
          if case .loading = viewModel.state.fetchResult {
            return true
          }
          return false
        }(),
      ) { action in
        switch action {
        case .fetchDidTap:
          Task { await viewModel.doAction(.view(.fetchDidTap)) }
        }
      }

      FetchResultSection(result: viewModel.state.fetchResult)
    }
    .navigationTitle("WebParser 實測")
  }
}

// MARK: - URLInputSection

private extension TitleTestView {
  struct URLInputSection: View {
    enum Action: Sendable {
      case fetchDidTap
    }

    @Binding var urlString: String
    let isLoading: Bool
    let send: (Action) -> Void

    var body: some View {
      Section("輸入網址") {
        TextField("https://...", text: $urlString)
          .keyboardType(.URL)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)

        Button {
          send(.fetchDidTap)
        } label: {
          if isLoading {
            ProgressView()
              .frame(maxWidth: .infinity)
          }
          else {
            Text("開始抓取網頁標題")
              .frame(maxWidth: .infinity)
          }
        }
        .disabled(isLoading)
      }
    }
  }
}

// MARK: - FetchResultSection

private extension TitleTestView {
  struct FetchResultSection: View {
    let result: TitleTestViewModel.FetchResult

    var body: some View {
      Section("抓取結果") {
        switch result {
        case .idle:
          Text("尚未有資料")
            .foregroundStyle(.secondary)

        case .loading:
          Text("連線中...")
            .foregroundStyle(.secondary)

        case let .success(title):
          Text("網頁標題：\n\(title)")
            .font(.system(.body, design: .monospaced))

        case let .failure(message):
          Text("錯誤：\(message)")
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.red)
        }
      }
    }
  }
}
