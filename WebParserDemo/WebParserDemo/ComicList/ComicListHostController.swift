//
//  ComicListHostController.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import SwiftUI
import UIKit

@MainActor
final class ComicListHostController: UIHostingController<ComicListView> {
  // MARK: - ViewModel

  private let viewModel: ComicListViewModel

  // MARK: - Init

  init(viewModel: ComicListViewModel) {
    self.viewModel = viewModel
    let view = ComicListView(viewModel: viewModel)
    super.init(rootView: view)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
