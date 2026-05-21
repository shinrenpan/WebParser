//
//  TitleTestHostController.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import SwiftUI
import UIKit

@MainActor
final class TitleTestHostController: UIHostingController<TitleTestView> {
  // MARK: - ViewModel

  private let viewModel: TitleTestViewModel

  // MARK: - Init

  init(viewModel: TitleTestViewModel) {
    self.viewModel = viewModel
    let view = TitleTestView(viewModel: viewModel)
    super.init(rootView: view)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
