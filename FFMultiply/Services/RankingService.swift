//
//  RankingService.swift
//  FFMultiply
//
//  Firebase Realtime Database を async/await でラップしたオンラインランキング。
//
//  自分のレコードは匿名認証の uid を key にして `scores_v2/<uid>` に置く。
//  以前の版は `scores/<identifierForVendor>` に認証なしで書いていたため、移行期間中は
//  両方を読んで順位を出し、`scores_v2` に登録できた端末は旧レコードを自分で消す。
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase

/// ランキングの 1 エントリ。
struct RankEntry: Identifiable, Equatable {
    let id = UUID()
    let rank: Int
    let score: Int
    let name: String
}

@MainActor
final class RankingService {
    static let shared = RankingService()

    /// ランキングに登録できる名前の最大文字数。
    static let maxNameLength = 20
    /// データベースのルールが許す名前の長さ（UTF-16 の単位数）。ルールは文字数ではなく
    /// この単位で数えるため、絵文字などで 20 文字がこれを超える場合はさらに切り詰める。
    private static let maxNameUTF16Length = 100

    private static let path = "scores_v2"
    private static let legacyPath = "scores"
    /// 起動時の登録し直しが済んだことを示す UserDefaults のキー。
    private static let migratedKey = "rankingMigratedToV2"
    /// 旧レコードを消し終えたことを示す UserDefaults のキー。
    private static let legacyRemovedKey = "rankingLegacyRemoved"

    /// ランキングの 1 行（並べ替え前）。
    private typealias Row = (key: String, score: Int, name: String)

    private let ref = Database.database().reference()
    private let storage = UserDefaults.standard
    /// 旧形式での自分の key。移行期間中の読み取りと後始末にだけ使う。
    private let legacyDeviceID = UIDevice.current.identifierForVendor?.uuidString

    /// ランキングに登録できる長さに名前を切り詰める。
    static func normalizedName(_ name: String) -> String {
        var name = String(name.prefix(maxNameLength))
        while name.utf16.count > maxNameUTF16Length {
            name.removeLast()
        }
        return name
    }

    /// スコアを登録する（priority = -score で降順に並ぶようにする）。
    func register(name: String, score: Int) {
        Task { await registerAndWait(name: name, score: score) }
    }

    /// スコアを登録し、書き込みが終わるまで待つ（登録直後にランキングを読み直すとき用）。
    func registerAndWait(name: String, score: Int) async {
        await write(name: name, score: score)
    }

    /// 自分のスコアを 0 にリセット（ローカル全削除時）。
    func reset(name: String) {
        Task { await write(name: name, score: 0) }
    }

    /// 以前の版で登録していた端末のために、端末内の最高スコアを一度だけ `scores_v2` に登録し直す。
    /// 旧レコードを読んで本人確認する必要が無いよう、手元のスコアと名前から作り直す。
    func migrateIfNeeded(bestScore: Int?, name: String?) async {
        guard !storage.bool(forKey: Self.migratedKey) else { return }
        // 名前かスコアが無ければ登録し直すものが無い。次に登録するときに `scores_v2` へ入る。
        guard let bestScore, let name, !name.isEmpty else { return }
        if await write(name: name, score: bestScore) {
            storage.set(true, forKey: Self.migratedKey)
        }
    }

    /// 全スコアを取得し、順位付けした配列を返す。
    /// 併せて自分の順位（見つからなければ 0）と、自分の行の並び順インデックス（無ければ nil）も返す。
    func fetchRanking() async -> (entries: [RankEntry], myRank: Int, myIndex: Int?) {
        let uid = await signedInUserID()
        async let current = rows(at: Self.path)
        async let legacy = rows(at: Self.legacyPath)
        var rows = await current
        let hasCurrentRecord = rows.contains { $0.key == uid }
        // 登録し直した端末の旧レコードがまだ残っていても、二重に並べない。
        rows += await legacy.filter { !(hasCurrentRecord && $0.key == legacyDeviceID) }
        let myKey = hasCurrentRecord ? uid : legacyDeviceID
        return Self.rank(rows, myKey: myKey)
    }

    // MARK: - 認証

    /// 匿名認証の uid。未サインインならサインインする。失敗したら nil。
    private func signedInUserID() async -> String? {
        if let user = Auth.auth().currentUser {
            return user.uid
        }
        do {
            return try await Auth.auth().signInAnonymously().user.uid
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    // MARK: - 書き込み

    /// 自分のレコードを書き込む。成功したら旧レコードを消す。
    @discardableResult
    private func write(name: String, score: Int) async -> Bool {
        let name = Self.normalizedName(name)
        guard !name.isEmpty, let uid = await signedInUserID() else { return false }
        let value: [String: Any] = ["name": name, "score": score as NSNumber]
        do {
            _ = try await ref.child(Self.path).child(uid).setValue(value, andPriority: -score)
        } catch {
            print(error.localizedDescription)
            return false
        }
        await removeLegacyRecordIfNeeded()
        return true
    }

    private func removeLegacyRecordIfNeeded() async {
        guard !storage.bool(forKey: Self.legacyRemovedKey), let legacyDeviceID else { return }
        do {
            _ = try await ref.child(Self.legacyPath).child(legacyDeviceID).removeValue()
            storage.set(true, forKey: Self.legacyRemovedKey)
        } catch {
            print(error.localizedDescription)
        }
    }

    // MARK: - 読み取り

    /// 指定した場所の全レコードを (key, score, name) に整形して返す。読めなければ空。
    private func rows(at path: String) async -> [Row] {
        let query = ref.child(path).queryOrderedByPriority()
        return await withCheckedContinuation { continuation in
            query.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: RankingService.rows(from: snapshot))
            } withCancel: { error in
                print(error.localizedDescription)
                continuation.resume(returning: [])
            }
        }
    }

    private nonisolated static func rows(from snapshot: DataSnapshot) -> [Row] {
        guard let values = snapshot.value as? [String: Any] else {
            return []
        }
        return values.compactMap { key, value in
            guard let dict = value as? [String: Any],
                  let score = (dict["score"] as? NSNumber)?.intValue else { return nil }
            let rawName = (dict["name"] as? String) ?? ""
            let name = rawName.isEmpty ? "No Name" : rawName
            return (key, score, name)
        }
    }

    /// score 降順に並べ、同点は同順位でランク付けする。
    private static func rank(_ rows: [Row], myKey: String?) -> (entries: [RankEntry], myRank: Int, myIndex: Int?) {
        var entries: [RankEntry] = []
        var myRank = 0
        var myIndex: Int?
        var currentRank = 0
        var previousScore: Int?
        for (index, row) in rows.sorted(by: { $0.score > $1.score }).enumerated() {
            if row.score != previousScore {
                currentRank = index + 1
                previousScore = row.score
            }
            entries.append(RankEntry(rank: currentRank, score: row.score, name: row.name))
            // 同点者がいても、自分の行は key で一意に特定する。
            if row.key == myKey {
                myRank = currentRank
                myIndex = index
            }
        }
        return (entries, myRank, myIndex)
    }
}
