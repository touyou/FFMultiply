//
//  ScreenshotTests.swift
//  FFMultiplyUITests
//
//  App Store 用のスクリーンショットを撮る。挙動のテストではなく、アプリを各画面まで
//  進めて画像を添付するだけ。`scripts/capture_screenshots.sh` が端末・言語ごとに実行し、
//  添付を取り出して `Screenshots/<platform>/<locale>/` に並べる。
//

import XCTest

final class ScreenshotTests: XCTestCase {
    /// どの画面を撮るときも付ける起動引数。
    ///
    /// 言語は `-AppleLanguages` ではなく `xcodebuild -testLanguage` で切り替える。
    /// こちらでないとアプリ側の `Locale.current` が変わらず、固定データ（ランキングの名前や
    /// ローカルスコアの日付）が撮影言語に合わない。
    private let baseArguments = ["-uitest-screenshot-fixture"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - 撮影

    /// 画面ごとにアプリを起動し直し、ホームから目的の画面を開いて撮る。
    /// sheet / fullScreenCover を閉じる手順（iPhone Duo では閉じるボタンが縦のバーへ移る）に
    /// 左右されないよう、毎回まっさらな状態から開く。
    @MainActor
    func testCaptureScreenshots() throws {
        // 1. ホーム
        var app = launch()
        settle()
        capture("01-home")

        // 2. プレイ中の盤面（タイマーは固定データで止めてある）
        app = launch()
        app.buttons["timeAttackButton"].tap()
        XCTAssertTrue(
            app.staticTexts["answerInput"].waitForExistence(timeout: 10),
            "ゲーム画面が開くはず"
        )
        settle()
        capture("02-game")

        // 3. リザルト（ハイスコア更新）
        app = launch(extraArguments: ["-uitest-screenshot-result"])
        app.buttons["timeAttackButton"].tap()
        XCTAssertTrue(
            app.staticTexts["resultScore"].waitForExistence(timeout: 10),
            "ゲームがすぐに終わってリザルトが出るはず"
        )
        settle()
        capture("03-result")

        // 4. オンラインランキング
        app = launch()
        app.buttons["onlineRankingButton"].tap()
        XCTAssertTrue(
            app.staticTexts["yourRankLabel"].waitForExistence(timeout: 10),
            "オンラインランキングが開くはず"
        )
        XCTAssertTrue(app.cells.element(boundBy: 0).waitForExistence(timeout: 10), "固定のランキングが並ぶはず")
        settle()
        capture("04-ranking")

        // 5. ローカルスコア
        app = launch()
        app.buttons["localScoreButton"].tap()
        XCTAssertTrue(
            app.cells.element(boundBy: 0).waitForExistence(timeout: 10),
            "固定のローカルスコアが並ぶはず"
        )
        settle()
        capture("05-local-score")
    }

    // MARK: - 補助

    /// アプリを起動し直し、ホームが出るまで待つ。
    @MainActor
    @discardableResult
    private func launch(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.terminate()
        app.launchArguments = baseArguments + extraArguments
        app.launch()
        XCTAssertTrue(
            app.buttons["timeAttackButton"].waitForExistence(timeout: 30),
            "ホームのメニューが出るはず"
        )
        return app
    }

    /// sheet や fade の表示アニメーションが終わるのを待つ。
    private func settle() {
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// 取り出しスクリプトが並べ替えられる名前で添付する。
    @MainActor
    private func capture(_ name: String) {
        // 端末のフレームバッファそのもの。App Store Connect が求めるピクセルサイズになる。
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        // 成功したテストの添付は既定で捨てられる。撮影は必ず成功するので、これが無いと何も残らない。
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
