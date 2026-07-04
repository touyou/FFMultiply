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
                    RealmMigration.migrateIfNeeded(context: container.mainContext)
                    AdManager.shared.loadInterstitial()
                }
        }
        .modelContainer(container)
    }
}
