//
//  StarterApp.swift
//  Starter
//
//  Created by Daniel Flores on 5/30/25.
//

import SwiftUI
import UIKit

@main
struct StarterApp: App {
    init() {
        // Make tab and navigation bars transparent so the gradient background
        // shows through instead of the default gray color.
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = .clear
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        UITabBar.appearance().tintColor = .orange

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = .clear
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.orange]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.orange]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(.orange)
        }
    }
}
