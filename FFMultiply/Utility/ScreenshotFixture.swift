//
//  ScreenshotFixture.swift
//  FFMultiply
//
//  App Store 用スクリーンショットの撮影（UI テスト `ScreenshotTests`）向けの固定データ。
//  起動引数 `-uitest-screenshot-fixture` を付けて Debug ビルドを起動したときだけ有効になり、
//  Release ビルドでは常に無効（通常の挙動は変わらない）。
//
//  有効な間は次のようにして、毎回同じ画面が撮れるようにする。
//  - Firebase を起動せず、ランキングは固定の一覧を表示する（本番のデータベースを読み書きしない）
//  - 広告・UMP の同意フォーム・ATT の許可ダイアログ・初回チュートリアルを出さない
//  - ローカルスコアはメモリ上の SwiftData に置いた固定の履歴を使う（端末の保存先に触れない）
//  - ゲームはタイマーを止め、固定の問題・入力・得点で表示する
//    （`-uitest-screenshot-result` を併せて付けると、開いた直後に終了してリザルトを出す）
//
//  名前などの文言は撮影時の言語（`xcodebuild -testLanguage`）に合わせて切り替える。
//

import Foundation
import SwiftData

enum ScreenshotFixture {
    /// 撮影用の固定データで動かすか。
    static var isActive: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-uitest-screenshot-fixture")
        #else
        false
        #endif
    }

    /// ゲーム画面を開いた直後に終了させ、リザルトを表示するか。
    static var showsResult: Bool {
        isActive && ProcessInfo.processInfo.arguments.contains("-uitest-screenshot-result")
    }

    private static var isJapanese: Bool {
        Locale.current.language.languageCode == .japanese
    }

    // MARK: - ゲーム

    /// プレイ中の盤面: B × 7 = 4D を 1 桁目まで入力したところ。
    static let problem: FFProblem = (.b, .seven, fTimes(.b, .seven))
    static let input = "4"
    static let playingScore = 185
    static let playingRemaining = 37

    /// リザルトの得点。ローカルの最高記録（`localScores` の先頭）より高くし、High Score を出す。
    static let resultScore = 260

    // MARK: - ローカルスコア

    /// ローカルスコアの履歴（得点, 日付）。日付も固定して撮影日によって変わらないようにする。
    private static let localScores: [(score: Int, date: String)] = [
        (230, "2026-10-18"), (215, "2026-10-20"), (190, "2026-10-12"), (185, "2026-10-21"),
        (160, "2026-10-05"), (145, "2026-10-09"), (120, "2026-09-28"), (95, "2026-09-24"),
        (80, "2026-09-20"), (60, "2026-09-18"),
    ]

    /// 固定の履歴を入れたメモリ上のコンテナを作る。
    @MainActor
    static func makeContainer() throws -> ModelContainer {
        let container = try ModelContainer(
            for: ScoreEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let store = ScoreStore(context: container.mainContext)
        for entry in localScores {
            store.add(score: entry.score, date: formatter.date(from: "\(entry.date) 12:00") ?? Date())
        }
        return container
    }

    // MARK: - オンラインランキング

    /// 自分の順位。`ranking` の中で自分の行がこの順位になるよう並べてある。
    static let myRank = 4

    /// オンラインランキングの一覧（同点は同順位）。
    static var ranking: [RankEntry] {
        let names = isJapanese ? japaneseNames : englishNames
        var entries: [RankEntry] = []
        var previousScore: Int?
        var currentRank = 0
        for (index, score) in rankingScores.enumerated() {
            if score != previousScore {
                currentRank = index + 1
                previousScore = score
            }
            entries.append(RankEntry(rank: currentRank, score: score, name: names[index % names.count]))
        }
        return entries
    }

    private static let rankingScores = [
        512, 385, 342, 300, 291, 288, 275, 260, 260, 248,
        236, 230, 221, 214, 205, 198, 190, 182, 175, 170,
        162, 155, 150, 141, 133, 128, 120, 112, 105, 96,
    ]

    // 4 番目（順位 4）が自分の行。
    private static let japaneseNames = [
        "ヘキサの民", "0xCAFE", "九九より FF", "FFマスター", "さくら",
        "じゅうろく", "ゆうき", "けいすけ", "ビット職人", "はると",
        "こはる", "みなと", "なつめ", "あおい", "そうた",
    ]
    private static let englishNames = [
        "HexWizard", "0xCAFE", "Ada", "FF Master", "Byte Rider",
        "Nibble", "Sam", "Olivia", "Leo", "Mia",
        "Noah", "Emma", "Hex Kid", "Lucas", "Grace",
    ]
}
