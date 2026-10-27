//
//  FFShortcuts.swift
//  FFMultiply
//
//  Siri / Spotlight のフレーズ。パッケージに置くとメタデータから落ちるのでアプリターゲットに置く。
//  日本語のフレーズは AppShortcuts.xcstrings にある。
//

import AppIntents

struct FFShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .lime

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimeAttackIntent(),
            phrases: [
                "Start a time attack in \(.applicationName)",
                "Play \(.applicationName)"
            ],
            shortTitle: "Time Attack",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: GetHighScoreIntent(),
            phrases: [
                "What's my high score in \(.applicationName)",
                "Show my \(.applicationName) high score"
            ],
            shortTitle: "High Score",
            systemImageName: "crown.fill"
        )
    }
}
