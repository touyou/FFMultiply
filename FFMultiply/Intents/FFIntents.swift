//
//  FFIntents.swift
//  FFMultiply
//
//  Siri / ショートカットから呼べる操作。ホーム画面の「time attack」ボタンも
//  StartTimeAttackIntent を通す。
//

import AppIntents
import SwiftData

/// タイムアタックを始める（アプリを開く）。
struct StartTimeAttackIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Time Attack"
    static let description = IntentDescription("Opens FFMultiplier and starts a 60-second time attack.")

    // supportedModes は iOS 26 から。iOS 18 では openAppWhenRun が使われる。
    static let openAppWhenRun = true
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Dependency private var navigator: AppNavigator

    @MainActor
    func perform() async throws -> some IntentResult {
        navigator.isPlayingTimeAttack = true
        return .result()
    }
}

/// 端末に保存されたハイスコアを答える。
struct GetHighScoreIntent: AppIntent {
    static let title: LocalizedStringResource = "Get High Score"
    static let description = IntentDescription("Tells your best time attack score on this device.")

    @Dependency private var container: ModelContainer

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        guard let best = ScoreStore(context: container.mainContext).highScore() else {
            return .result(value: 0, dialog: "You haven't played a time attack yet.")
        }
        return .result(value: best.score, dialog: "Your high score is \(best.score).")
    }
}
