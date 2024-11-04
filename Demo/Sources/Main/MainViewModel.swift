//
//  MainViewModel.swift
//
//  Created by Shinren Pan on 2024/7/25.
//

import Observation
import UIKit
import WebParser

extension Main {
    @MainActor
    @Observable
    final class ViewModel {
        private(set) var state = State.none
        
        // MARK: - Public
        
        func doAction(_ action: Action) {
            switch action {
            case .loadData:
                actionLoadData()
            }
        }
        
        // MARK: - Handle Action
        
        func actionLoadData() {
            Task {
                do {
                    let parser = makeParser()
                    let comics = try await parser.decodeResult([DisplayComic].self)
                    state = .dataLoaded(response: .init(comics: comics))
                }
                catch {
                    print(error)
                }
            }
        }
        
        // MARK: - Make Something
        
        func makeParser() -> Parser {
            let configuration = ParserConfiguration(
                request: makeRequest(),
                windowSize: makeWindowSize(),
                customUserAgent: makeUserAgent(),
                retryCount: 10,
                retryDuration: 3,
                javascript: makeJS()
            )
            
            return .init(parserConfiguration: configuration)
        }
        
        func makeRequest() -> URLRequest {
            URLRequest(url: .init(string: "https://www.manhuagui.com/update/")!)
        }
        
        func makeWindowSize() -> CGSize {
            .init(width: 1920, height: 1080)
        }
        
        func makeUserAgent() -> String {
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15"
        }
        
        func makeJS() -> String {
            return """
            var results = [];
            var list = $('.latest-list > ul > li');
            list.each(function() {
            var comic = new Object();
            comic.title = $(this).find('a').eq(0).attr('title');
            results.push(comic);
            });
            results;
            """
        }
    }
}
