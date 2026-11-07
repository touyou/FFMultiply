//
//  ScoreService.swift
//  FFMultiply
//
//  スコアの読み出し・全削除と、オンラインランキングへの登録・退会。画面と App Intent の両方がここを通す。
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class ScoreService {
    private let container: ModelContainer
    /// 画面から頼んだランキング削除が通信で失敗したか。スコア画面と設定画面がアラートを出す。
    /// Siri から頼んだ失敗はその場のダイアログで伝えるので立てない（立てると後で開いた画面に古いアラートが出る）。
    var rankingDeleteFailed = false
    /// ランキングに出す名前。Intent が消したときに設定画面の入力欄も追従できるよう、ここで持つ。
    var playerName: String {
        didSet { storage.set(playerName, forKey: Self.playerNameKey) }
    }

    /// 最後にランキングへ登録できた時刻。ランキング画面はこれが変わったら読み直す（Siri から登録したときも）。
    private(set) var lastRegistration: Date?

    private static let playerNameKey = "playername"
    private let storage = UserDefaults.standard

    init(container: ModelContainer) {
        self.container = container
        playerName = storage.string(forKey: Self.playerNameKey) ?? ""
    }

    /// ランキングに登録できる長さに切り詰めて名前を変える。設定画面と SetUserNameIntent が通す。
    func setPlayerName(_ name: String) {
        playerName = RankingService.normalizedName(name)
    }

    func highScore() -> ScoreEntry? {
        ScoreStore(context: container.mainContext).highScore()
    }

    /// 端末のスコアをすべて消し、オンラインランキングの自分の記録も消す。ランキングまで消せたら true。
    @discardableResult
    func deleteAll(alertOnFailure: Bool = false) async -> Bool {
        ScoreStore(context: container.mainContext).deleteAll()
        return await deleteFromRanking(alertOnFailure: alertOnFailure)
    }

    @discardableResult
    func deleteFromRanking(alertOnFailure: Bool = false) async -> Bool {
        let succeeded = await RankingService.shared.deleteMyRecords()
        if alertOnFailure { rankingDeleteFailed = !succeeded }
        return succeeded
    }

    /// 端末のハイスコアを今の名前でランキングに登録する。
    func registerHighScore() async throws {
        guard !playerName.isEmpty else { throw RankingError.noPlayerName }
        guard let best = highScore() else { throw RankingError.noScore }
        guard await RankingService.shared.registerAndWait(name: playerName, score: best.score) else {
            throw RankingError.offline
        }
        lastRegistration = .now
    }

    /// ランキングから自分の記録を消し、名前も消す（名前が残ると次のプレイで自動登録され直す）。
    @discardableResult
    func leaveRanking(alertOnFailure: Bool = false) async -> Bool {
        guard await deleteFromRanking(alertOnFailure: alertOnFailure) else { return false }
        playerName = ""
        return true
    }
}

enum RankingError: Error, CustomLocalizedStringResourceConvertible {
    case noPlayerName, noScore, offline

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noPlayerName: "Set a user name in Settings first."
        case .noScore: "You haven't played a time attack yet."
        case .offline: "Couldn't reach the online ranking. Check your connection and try again."
        }
    }
}
