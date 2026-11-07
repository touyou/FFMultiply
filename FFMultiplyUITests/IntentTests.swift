//
//  IntentTests.swift
//  FFMultiplyUITests
//
//  App Intents を AppIntentsTesting で動いているアプリに対して実行する。Siri のフレーズの
//  聞き取りまでは届かないので、フレーズは実機の Siri で確かめる。
//
//  `-uitest-screenshot-fixture` で起動し、ローカルスコアはメモリ上の固定の履歴、
//  ランキングは Firebase に触れない固定の一覧で動かす。名前（UserDefaults）を書き換える
//  Intent はシミュレーターの設定を汚すのでここでは実行しない。
//
//  AppIntentsTesting は iOS 27 からなので、UI テストターゲットのデプロイメントターゲットは 27.0。
//  `CODE_SIGNING_ALLOWED=NO` を付けた `test` では AppIntentsTesting が Code=803 で全件失敗する。
//

import AppIntentsTesting
import XCTest

final class IntentTests: XCTestCase {
    private var app: XCUIApplication!
    private var definitions: IntentDefinitions!

    /// 固定の履歴（ScreenshotFixture.localScores）の最高点。
    private let fixtureHighScore = 230

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitest-screenshot-fixture"]
        app.launch()
        definitions = IntentDefinitions(bundleIdentifier: "com.dev.touyou.FFMultiply")
        try await waitForMetadata()
    }

    // MARK: - 値を返す Intent

    @MainActor
    func testGetHighScoreAnswersTheBestLocalScore() async throws {
        let result = try await definitions.intents["GetHighScoreIntent"].makeIntent().run()
        let best: Int = try result.value
        XCTAssertEqual(best, fixtureHighScore)
    }

    // MARK: - 画面を開く Intent

    @MainActor
    func testShowScoresOpensTheLocalScoreList() async throws {
        let board = AnyAppEnum(typeIdentifier: "ScoreBoard", rawValue: "local")
        try await definitions.intents["ShowScoresIntent"].makeIntent(board: board).run()
        XCTAssertTrue(
            app.descendants(matching: .any)["localScoreList"].waitForExistence(timeout: 10),
            "ShowScoresIntent(board: .local) でローカルスコアの一覧が開くはず"
        )
    }

    // MARK: - 準備

    /// インストール直後はメタデータが届くまで Code=400 で失敗するので、読むだけの Intent で待つ。
    /// 署名の不備（AppIntentsServicesSecurityErrorDomain）は待っても直らないのですぐ落とす。
    @MainActor
    private func waitForMetadata(timeout: TimeInterval = 30) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        var lastError: (any Error)?
        while Date() < deadline {
            do {
                try await definitions.intents["GetHighScoreIntent"].makeIntent().run()
                return
            } catch {
                if (error as NSError).domain == "AppIntentsServicesSecurityErrorDomain" { throw error }
                lastError = error
                try await Task.sleep(for: .milliseconds(500))
            }
        }
        XCTFail("App Intents のメタデータが届かなかった: \(String(describing: lastError))")
    }
}
