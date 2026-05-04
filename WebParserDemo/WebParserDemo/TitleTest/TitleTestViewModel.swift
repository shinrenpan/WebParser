//
//  TitleTestViewModel.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation
import Observation
import WebParser

@Observable
@MainActor
final class TitleTestViewModel {
  // MARK: - ViewModel

  enum Action: Sendable {
    case view(ViewAction)
    case apiRequest(APIRequest)
    case apiResponse(APIResponse)
  }

  // MARK: - State

  var state: State = .init()

  // MARK: - Private

  @ObservationIgnored
  private let parser: WebParser = .init()

  func doAction(_ action: Action) async {
    switch action {
    case let .view(action): await handleViewAction(action)
    case let .apiRequest(action): await handleAPIRequest(action)
    case let .apiResponse(action): handleAPIResponse(action)
    }
  }
}

// MARK: - ViewAction

extension TitleTestViewModel {
  enum ViewAction: Sendable {
    case fetchDidTap
  }

  private func handleViewAction(_ action: ViewAction) async {
    switch action {
    case .fetchDidTap:
      guard let url = URL(string: state.urlString) else {
        state.fetchResult = .failure("無效的網址")
        return
      }

      await doAction(.apiRequest(.fetchTitle(url)))
    }
  }
}

// MARK: - APIRequest

extension TitleTestViewModel {
  enum APIRequest: Sendable {
    case fetchTitle(URL)
  }

  private func handleAPIRequest(_ action: APIRequest) async {
    switch action {
    case let .fetchTitle(url):
      await fetchTitle(url)
    }
  }

  private func fetchTitle(_ url: URL) async {
    state.fetchResult = .loading

    let config = WebParserConfig(url: url, executionJS: "document.title")

    do {
      let title = try await parser.parse(
        with: config,
        mapper: WebParserRegexMapper<String> { data in
          guard let raw = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
          }

          // JS 以 JSON 格式回傳字串時會帶有引號，需去除
          return raw.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        },
      )
      await doAction(.apiResponse(.fetchTitleSuccess(title)))
    }
    catch is CancellationError {
      state.fetchResult = .idle
    }
    catch {
      await doAction(.apiResponse(.fetchTitleFailure(error.localizedDescription)))
    }
  }
}

// MARK: - APIResponse

extension TitleTestViewModel {
  enum APIResponse: Sendable {
    case fetchTitleSuccess(String)
    case fetchTitleFailure(String)
  }

  private func handleAPIResponse(_ action: APIResponse) {
    switch action {
    case let .fetchTitleSuccess(title):
      state.fetchResult = .success(title)
    case let .fetchTitleFailure(message):
      state.fetchResult = .failure(message)
    }
  }
}
