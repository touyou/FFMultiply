//
//  FFMultiplyApp.swift
//  FFMultiply
//
//  SwiftUI アプリのエントリポイント。SwiftData コンテナの構築、
//  旧 Realm データの一度きり移行、広告の同意取得と事前ロードを起動時に行う。
//

import SwiftUI
import SwiftData

@main
struct FFMultiplyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let container: ModelContainer

    init() {
        do {
            // スクリーンショット撮影中は端末の保存先ではなく、固定の履歴を入れたメモリ上のコンテナを使う。
            container = ScreenshotFixture.isActive
                ? try ScreenshotFixture.makeContainer()
                : try ModelContainer(for: ScoreEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .task {
                    // スクリーンショット撮影中は同意・ATT の確認もランキングの移行もしない。
                    guard !ScreenshotFixture.isActive else { return }
                    // 広告の同意（UMP）→ ATT の許可 → 広告 SDK 起動 → 広告のロード。
                    await AdManager.shared.prepareAds()
                    await RankingService.shared.migrateIfNeeded(
                        bestScore: ScoreStore(context: container.mainContext).highScore()?.score,
                        name: UserDefaults.standard.string(forKey: "playername")
                    )
                }
        }
        .modelContainer(container)
    }
}
