//
//  AppDelegate.swift
//
//  Created by Shinren Pan on 2024/7/25.
//

import UIKit

@main class AppDelegate: UIResponder {
    var window: UIWindow?
}

// MARK: - UIApplicationDelegate

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let bounds = UIScreen.main.bounds
        let window = UIWindow(frame: bounds)
        window.backgroundColor = .white
        window.rootViewController = DemoVC()
        self.window = window
        window.makeKeyAndVisible()
        
        return true
    }
}
