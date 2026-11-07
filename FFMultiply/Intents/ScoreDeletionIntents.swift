//
//  ScoreDeletionIntents.swift
//  FFMultiply
//
//  消す操作の Intent。Siri / ショートカットからは requestConfirmation で確認してから消し、
//  画面の確認アラートからは確認なしの版（…NowIntent）を呼ぶ。アプリ内のボタンからは
//  requestConfirmation を出せないため、確認する Intent はボタンから呼ばない。
//

import AppIntents

/// 端末のスコアをすべて消す（オンラインランキングの自分の記録も）。Siri からは確認してから消す。
struct DeleteAllScoresIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete All Scores"
    static let description = IntentDescription("Deletes all your scores on this device and your records in the online ranking.")
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    @Dependency private var scores: ScoreService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await requestConfirmation(dialog: "Delete all your scores? They will also be removed from the online ranking.")
        return .result(dialog: await scores.deleteAll()
            ? "Deleted all your scores."
            : "Deleted your scores on this device, but couldn't reach the online ranking.")
    }
}

/// 画面の確認アラートから呼ぶ、確認なしの版。アプリ内のボタンから requestConfirmation は出せない。
struct DeleteAllScoresNowIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete All Scores Without Asking"
    static let isDiscoverable = false
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    @Dependency private var scores: ScoreService

    @MainActor
    func perform() async throws -> some IntentResult {
        await scores.deleteAll()
        return .result()
    }
}

/// オンラインランキングから自分の記録と名前を消す。Siri からは確認してから消す。
struct LeaveRankingIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete from Online Ranking"
    static let description = IntentDescription("Removes your name and scores from the online ranking and clears your user name.")
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    @Dependency private var scores: ScoreService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await requestConfirmation(dialog: "Remove your name and scores from the online ranking?")
        guard await scores.leaveRanking() else { throw RankingError.offline }
        return .result(dialog: "Removed you from the online ranking.")
    }
}

/// 設定画面の確認アラートから呼ぶ、確認なしの版。
struct LeaveRankingNowIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete from Online Ranking Without Asking"
    static let isDiscoverable = false
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    @Dependency private var scores: ScoreService

    @MainActor
    func perform() async throws -> some IntentResult {
        await scores.leaveRanking()
        return .result()
    }
}
