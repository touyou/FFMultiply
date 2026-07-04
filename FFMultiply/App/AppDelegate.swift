//
//  AppDelegate.swift
//  FFMultiply
//
//  Firebase と Google Mobile Ads の起動のみを担う軽量 AppDelegate。
//

import UIKit
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        AdManager.shared.start()
        return true
    }
}
