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
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .black
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        UITabBar.appearance().tintColor = .orange

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = .black
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.orange]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.orange]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.orange
        UISegmentedControl.appearance().backgroundColor = UIColor.black
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.orange], for: .normal)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(.orange)
        }
    }
}
