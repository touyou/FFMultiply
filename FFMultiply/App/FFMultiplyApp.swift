//
//  FFMultiplyApp.swift
//  FFMultiply
//
//  SwiftUI アプリのエントリポイント。SwiftData コンテナの構築、
//  旧 Realm データの一度きり移行、広告の同意取得と事前ロードを起動時に行う。
//

import SwiftUI
import SwiftData
import AppIntents

@main
struct FFMultiplyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let container: ModelContainer
    @State private var navigator: AppNavigator
    @State private var scores: ScoreService

    init() {
        do {
            // スクリーンショット撮影中は端末の保存先ではなく、固定の履歴を入れたメモリ上のコンテナを使う。
            container = ScreenshotFixture.isActive
                ? try ScreenshotFixture.makeContainer()
                : try ModelContainer(for: ScoreEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        // Siri から起動されたときは画面より先に Intent が走るので、ここで同期的に登録する。
        let navigator = AppNavigator()
        _navigator = State(initialValue: navigator)
        // `dependency:` はエスケープするクロージャなので、self ではなくローカルを渡す。
        let container = container
        let scores = ScoreService(container: container)
        _scores = State(initialValue: scores)
        AppDependencyManager.shared.add(dependency: container)
        AppDependencyManager.shared.add(dependency: navigator)
        AppDependencyManager.shared.add(dependency: scores)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(navigator)
                .environment(scores)
                .task {
                    // スクリーンショット撮影中は同意・ATT の確認もランキングの移行もしない。
                    guard !ScreenshotFixture.isActive else { return }
                    // 広告の同意（UMP）→ ATT の許可 → 広告 SDK 起動 → 広告のロード。
                    await AdManager.shared.prepareAds()
                    await RankingService.shared.migrateIfNeeded(
                        bestScore: scores.highScore()?.score,
                        name: scores.playerName
                    )
                }
        }
        .modelContainer(container)
    }
}
