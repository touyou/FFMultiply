//
//  ScreenshotTests.swift
//  FFMultiplyUITests
//
//  App Store 用のスクリーンショットを撮る。挙動のテストではなく、アプリを各画面まで
//  進めて画像を添付するだけ。`scripts/capture_screenshots.sh` が端末・言語ごとに実行し、
//  添付を取り出して `Screenshots/<platform>/<locale>/` に並べる。
//

import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {
    /// どの画面を撮るときも付ける起動引数。
    ///
    /// 言語は `-AppleLanguages` ではなく `xcodebuild -testLanguage` で切り替える。
    /// こちらでないとアプリ側の `Locale.current` が変わらず、固定データ（ランキングの名前や
    /// ローカルスコアの日付）が撮影言語に合わない。
    private let baseArguments = ["-uitest-screenshot-fixture"]

    /// iPhone Duo を開いた状態で撮るとき、スクリプトが `TEST_RUNNER_SCREENSHOT_DUO_OPEN=1` で立てる。
    private let isDuoOpen = ProcessInfo.processInfo.environment["SCREENSHOT_DUO_OPEN"] == "1"

    // XCTest の setUp は nonisolated なので、main actor の XCUIDevice は MainActor.run で触る。
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        // 開いた Duo は横向きで撮る。向きはスクリプト側の回転（時計回り 90°）と対になっている。
        if isDuoOpen {
            await MainActor.run { XCUIDevice.shared.orientation = .landscapeLeft }
        }
    }

    // MARK: - 撮影

    /// 画面ごとにアプリを起動し直し、ホームから目的の画面を開いて撮る。
    /// sheet / fullScreenCover を閉じる手順（iPhone Duo では閉じるボタンが縦のバーへ移る）に
    /// 左右されないよう、毎回まっさらな状態から開く。
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

    /// 撮る画面。ふだんは `XCUIScreen.main`。
    ///
    /// iPhone Duo は外側と内側の 2 枚の画面を持ち、`XCUIScreen.main` は開いていても外側を返す。
    /// 開いた状態では画素数がいちばん大きい画面（内側）を撮る。内側のフレームバッファは縦長のままなので、
    /// 横向きへの回転とサイズ合わせはスクリプトが行う。
    private func screenToCapture() -> XCUIScreen {
        guard isDuoOpen else { return XCUIScreen.main }
        func pixels(_ screen: XCUIScreen) -> CGFloat {
            let size = screen.screenshot().image.size
            return size.width * size.height
        }
        return XCUIScreen.screens.max { pixels($0) < pixels($1) } ?? XCUIScreen.main
    }

    /// 取り出しスクリプトが並べ替えられる名前で添付する。
    private func capture(_ name: String) {
        // 端末のフレームバッファそのもの。App Store Connect が求めるピクセルサイズになる。
        let attachment = XCTAttachment(screenshot: screenToCapture().screenshot())
        attachment.name = name
        // 成功したテストの添付は既定で捨てられる。撮影は必ず成功するので、これが無いと何も残らない。
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
