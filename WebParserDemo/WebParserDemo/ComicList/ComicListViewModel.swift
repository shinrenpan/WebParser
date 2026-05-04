//
//  ComicListViewModel.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import Foundation
import Observation
import WebParser

@Observable
@MainActor
final class ComicListViewModel {
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

  // MARK: - Init

  init() {
    parser.delegate = self
  }

  func doAction(_ action: Action) async {
    switch action {
    case let .view(action): await handleViewAction(action)
    case let .apiRequest(action): await handleAPIRequest(action)
    case let .apiResponse(action): handleAPIResponse(action)
    }
  }
}

extension ComicListViewModel: WebParserProgressDelegate {
  func webParser(_ parser: WebParser, didUpdateState parserState: WebParserState) {
    switch parserState {
    case let .loading(progress):
      state.loadingState = .loading(progress)
    case let .retrying(attempt, error):
      print("第 \(attempt) 次重試, 原因: \(error.localizedDescription)")
    default:
      break
    }
  }
}

// MARK: - ViewAction

extension ComicListViewModel {
  enum ViewAction: Sendable {
    case onAppear
    case refreshDidTrigger
    case retryDidTap
  }

  private func handleViewAction(_ action: ViewAction) async {
    switch action {
    case .onAppear:
      guard state.comics.isEmpty else {
        return
      }

      await doAction(.apiRequest(.fetchComics))

    case .refreshDidTrigger, .retryDidTap:
      await doAction(.apiRequest(.fetchComics))
    }
  }
}

// MARK: - APIRequest

extension ComicListViewModel {
  private static let comicJS = #"""
  (function() {
      var results = [];
      if (typeof $ === 'undefined') return [];

      var list = $('.latest-list > ul > li');
      if (list.length === 0) return [];

      var count = list.length;
      var now = Math.floor(Date.now() / 1000);

      list.each(function() {
          var item = $(this);
          var comic = {};

          var href = item.find('a').attr('href') || "";
          var idMatch = href.match(/\/comic\/(\d+)/);
          comic.id = idMatch ? idMatch[1] : href.replace(/\//g, '');

          comic.title = item.find('a').attr('title') || item.find('dt').text().trim() || "未知漫畫";

          var img = item.find('img');
          comic.cover = img.attr('data-src') || img.attr('src') || "";

          comic.note = item.find('.tt').text().trim();

          var dateStr = item.find('em').text().trim();
          var timestamp = 0;

          if (dateStr.includes('今天')) {
              timestamp = now;
          } else if (dateStr.includes('昨天')) {
              timestamp = now - 86400;
          } else {
              var parsed = Date.parse(dateStr);
              timestamp = isNaN(parsed) ? now : Math.floor(parsed / 1000);
          }

          comic.lastUpdate = timestamp + count;
          results.push(comic);
          count--;
      });

      return results;
  })();
  """#

  enum APIRequest: Sendable {
    case fetchComics
  }

  private func handleAPIRequest(_ action: APIRequest) async {
    switch action {
    case .fetchComics:
      await fetchComics()
    }
  }

  private func fetchComics() async {
    state.loadingState = .loading(0)

    let config = WebParserConfig(
      url: URL(string: "https://www.manhuagui.com/update/")!,
      userAgent: .custom(
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15",
      ),
      executionJS: Self.comicJS,
      windowSize: CGSize(width: 1920, height: 1080),
    )

    do {
      let comics = try await parser.parse(with: config, mapper: WebParserJSJSONMapper<[Comic]>())
      await doAction(.apiResponse(.fetchComicsSuccess(comics)))
    }
    catch is CancellationError {
      state.loadingState = .idle
    }
    catch {
      await doAction(.apiResponse(.fetchComicsFailure(error.localizedDescription)))
    }
  }
}

// MARK: - APIResponse

extension ComicListViewModel {
  enum APIResponse: Sendable {
    case fetchComicsSuccess([Comic])
    case fetchComicsFailure(String)
  }

  private func handleAPIResponse(_ action: APIResponse) {
    switch action {
    case let .fetchComicsSuccess(comics):
      state.comics = comics
      state.loadingState = .success

    case let .fetchComicsFailure(message):
      state.loadingState = .failure(message)
    }
  }
}
