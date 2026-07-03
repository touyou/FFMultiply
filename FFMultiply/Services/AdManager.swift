//
//  AdManager.swift
//  FFMultiply
//
//  Google Mobile Ads SDK v12+（Swift、`GAD` プレフィックス撤廃）のラッパー。
//  MobileAds の起動とインタースティシャル広告の load / present を担う。
//

import Foundation
import UIKit
import GoogleMobileAds

@Observable
@MainActor
final class AdManager {
    static let shared = AdManager()

    /// 広告ユニットID（現行踏襲）。
    static let bannerAdUnitID = "ca-app-pub-2853999389157478/6345144062"
    static let interstitialAdUnitID = "ca-app-pub-2853999389157478/3692728869"

    private var interstitial: InterstitialAd?

    private init() {}

    /// SDK を起動する（アプリ起動時に一度）。
    func start() {
        MobileAds.shared.start(completionHandler: nil)
    }

    /// インタースティシャル広告を事前ロードする。
    func loadInterstitial() {
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
