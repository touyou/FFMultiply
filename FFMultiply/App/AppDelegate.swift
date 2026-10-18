//
//  AppDelegate.swift
//  FFMultiply
//
//  Firebase の起動のみを担う軽量 AppDelegate。
//  Google Mobile Ads は同意の取得後に起動する（`AdManager.prepareAds()`）。
//

import UIKit
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
