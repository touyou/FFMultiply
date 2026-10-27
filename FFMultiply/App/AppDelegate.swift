//
//  AppDelegate.swift
//  FFMultiply
//
//  Firebase の起動のみを担う軽量 AppDelegate。
//  Google Mobile Ads は同意の取得後に起動する（`AdManager.prepareAds()`）。
//

import UIKit
import FirebaseCore
import FirebaseAppCheck

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // スクリーンショット撮影中は本番のデータベースに触れないよう Firebase を起動しない。
        guard !ScreenshotFixture.isActive else { return true }
        // `configure()` より前に設定しないと、最初のリクエストにトークンが付かない。
        AppCheck.setAppCheckProviderFactory(FFAppCheckProviderFactory())
        FirebaseApp.configure()
        return true
    }
}
