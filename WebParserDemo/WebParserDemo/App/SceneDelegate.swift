//
//  SceneDelegate.swift
//  WebParserDemo
//
//  Created by Joe Pan on 2026/02/02.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  // MARK: - UIWindowSceneDelegate

  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions,
  ) {
    guard let windowScene = scene as? UIWindowScene else {
      return
    }

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = makeRootViewController()
    window.makeKeyAndVisible()
    self.window = window
  }
}

// MARK: - Private

private extension SceneDelegate {
  func makeRootViewController() -> UITabBarController {
    let tabBar = UITabBarController()
    tabBar.viewControllers = [makeTitleTestNav(), makeComicListNav()]
    return tabBar
  }

  func makeTitleTestNav() -> UINavigationController {
    let vc = TitleTestHostController(viewModel: .init())
    vc.tabBarItem = UITabBarItem(
      title: "標題測試",
      image: UIImage(systemName: "text.magnifyingglass"),
      tag: 0,
    )
    return UINavigationController(rootViewController: vc)
  }

  func makeComicListNav() -> UINavigationController {
    let vc = ComicListHostController(viewModel: .init())
    vc.tabBarItem = UITabBarItem(
      title: "漫畫更新",
      image: UIImage(systemName: "books.vertical"),
      tag: 1,
    )
    return UINavigationController(rootViewController: vc)
  }
}
