//
//  FFMultiplyApp.swift
//  FFMultiply
//
//  SwiftUI アプリのエントリポイント。SwiftData コンテナの構築、
//  旧 Realm データの一度きり移行、広告の事前ロードを起動時に行う。
//

import SwiftUI
import SwiftData

@main
struct FFMultiplyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: ScoreEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .task {
                    // ATT の許可を求めてから広告をロードする（許可状況に応じて配信が決まる）。
                    await AdManager.shared.requestTrackingAuthorization()
                    AdManager.shared.loadInterstitial()
                }
        }
        .modelContainer(container)
    }
}
