//
//  FFIntents.swift
//  FFMultiply
//
//  Siri / ショートカットから呼べる操作。ホーム画面の「time attack」ボタンも
//  StartTimeAttackIntent を通す。
//

import AppIntents

/// タイムアタックを始める（アプリを開く）。
struct StartTimeAttackIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Time Attack"
    static let description = IntentDescription("Opens FFMultiplier and starts a 60-second time attack.")

    // supportedModes は iOS 26 から。iOS 18 では openAppWhenRun が使われる。
    static let openAppWhenRun = true
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    @Dependency private var navigator: AppNavigator

    @MainActor
    func perform() async throws -> some IntentResult {
        navigator.startTimeAttack()
        return .result()
    }
}

/// 端末に保存されたハイスコアを答える。
struct GetHighScoreIntent: AppIntent {
    static let title: LocalizedStringResource = "Get High Score"
    static let description = IntentDescription("Tells your best time attack score on this device.")
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    @Dependency private var scores: ScoreService

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        guard let best = scores.highScore() else {
            return .result(value: 0, dialog: "You haven't played a time attack yet.")
        }
        return .result(value: best.score, dialog: "Your high score is \(best.score).")
    }
}

/// どちらのスコア一覧か。
enum ScoreBoard: String, AppEnum {
    case local, online

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Score Board"
    static let caseDisplayRepresentations: [ScoreBoard: DisplayRepresentation] = [
        .local: "Scores on This Device",
        .online: "The Online Ranking",
    ]
}

/// 端末のスコア一覧かオンラインランキングを開く。ホーム画面のボタンもこれを通す。
struct ShowScoresIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Scores"
    static let description = IntentDescription("Opens your local scores or the online ranking.")

    static let openAppWhenRun = true
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$board)")
    }

    @Parameter(title: "Score Board", default: .local)
    var board: ScoreBoard

    @Dependency private var navigator: AppNavigator

    init() {}

    init(board: ScoreBoard) {
        self.board = board
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        await navigator.show(board == .local ? .localScore : .onlineRanking)
        return .result()
    }
}

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

/// 端末のハイスコアを、設定した名前でオンラインランキングに登録する。ランキング画面のボタンもこれを通す。
struct RegisterHighScoreIntent: AppIntent {
    static let title: LocalizedStringResource = "Register High Score"
    static let description = IntentDescription("Registers your best score on this device to the online ranking with your user name.")
    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { [.main] }

    @Dependency private var scores: ScoreService

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await scores.registerHighScore()
        return .result(dialog: "Registered your high score to the online ranking.")
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
