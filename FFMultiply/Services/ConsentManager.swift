//
//  ConsentManager.swift
//  FFMultiply
//
//  Google User Messaging Platform (UMP) のラッパー。EEA・英国などで必要な
//  広告の同意フォーム（GDPR メッセージ）を起動時に出し、設定画面から
//  プライバシーの設定（同意の変更）を開けるようにする。
//  同意が取れる（`canRequestAds` が true になる）までは広告 SDK を起動しない。
//

import Foundation
import UIKit
import UserMessagingPlatform

@Observable
@MainActor
final class ConsentManager {
    static let shared = ConsentManager()

    /// 広告をリクエストしてよい状態か（同意済み、または同意が不要な地域）。
    private(set) var canRequestAds = false

    /// 設定画面に「プライバシーの設定」を出す必要があるか。
    private(set) var isPrivacyOptionsRequired = false

    private init() {}

    /// 同意情報を更新し、必要なら同意フォームを表示する（アプリ起動時に一度）。
    /// 失敗しても前回までの同意状況で `canRequestAds` を判定する。
    func gatherConsent() async {
        let parameters = RequestParameters()
        #if DEBUG
        // 起動引数 `-umpDebugEEA` で EEA からのアクセスとして振る舞わせる（フォームの確認用）。
        if ProcessInfo.processInfo.arguments.contains("-umpDebugEEA") {
            let debugSettings = DebugSettings()
            debugSettings.geography = .EEA
            parameters.debugSettings = debugSettings
        }
        #endif

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            try await ConsentForm.loadAndPresentIfRequired(from: AdManager.rootViewController())
        } catch {
            print("Failed to gather consent: \(error.localizedDescription)")
        }
        refresh()
    }

    /// プライバシーの設定フォームを表示する（同意の変更・撤回）。
    func presentPrivacyOptionsForm() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: AdManager.rootViewController())
        } catch {
            print("Failed to present privacy options form: \(error.localizedDescription)")
        }
        refresh()
    }

    private func refresh() {
        canRequestAds = ConsentInformation.shared.canRequestAds
        isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
}
