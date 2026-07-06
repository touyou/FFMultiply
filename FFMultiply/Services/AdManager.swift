//
//  AdManager.swift
//  FFMultiply
//
//  Google Mobile Ads SDK v12+（Swift、`GAD` プレフィックス撤廃）のラッパー。
//  MobileAds の起動とインタースティシャル広告の load / present を担う。
//

import Foundation
import UIKit
import AppTrackingTransparency
import GoogleMobileAds

@Observable
@MainActor
final class AdManager {
    static let shared = AdManager()

    /// 広告ユニットID（現行踏襲）。
    static let bannerAdUnitID = "ca-app-pub-2853999389157478/6345144062"
    static let interstitialAdUnitID = "ca-app-pub-2853999389157478/3692728869"

    private var interstitial: InterstitialAd?

    /// スクリーンショット / UI テスト用に広告一式を無効化するフラグ。
    /// 起動引数 `-disableAds` を付けて実行すると true になる（App Store 用スクショで
    /// 「Test Ad」表示の広告が写り込まないようにするため）。
    static var adsDisabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-disableAds")
    }

    private init() {}

    /// SDK を起動する（アプリ起動時に一度）。
    func start() {
        guard !Self.adsDisabled else { return }
        MobileAds.shared.start(completionHandler: nil)
    }

    /// App Tracking Transparency の許可をリクエストする。
    /// 未決定のときのみプロンプトが表示される。アプリがアクティブな状態で呼ぶこと。
    /// 許可が得られた場合のみ AdMob が IDFA を用いたパーソナライズ広告を配信する。
    func requestTrackingAuthorization() async {
        guard !Self.adsDisabled else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    /// インタースティシャル広告を事前ロードする。
    func loadInterstitial() {
        guard !Self.adsDisabled else { return }
        Task {
            do {
                interstitial = try await InterstitialAd.load(
                    with: Self.interstitialAdUnitID,
                    request: Request()
                )
            } catch {
                print("Failed to load interstitial: \(error.localizedDescription)")
                interstitial = nil
            }
        }
    }

    /// ロード済みならインタースティシャルを表示し、次回用に再ロードする。
    func presentInterstitial() {
        guard !Self.adsDisabled else { return }
        guard let interstitial, let root = Self.rootViewController() else { return }
        interstitial.present(from: root)
        self.interstitial = nil
        loadInterstitial()
    }

    /// 現在の最前面のビューコントローラを取得する。
    static func rootViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
