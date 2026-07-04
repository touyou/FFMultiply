//
//  RankingService.swift
//  FFMultiply
//
//  Firebase Realtime Database を async/await でラップしたオンラインランキング。
//

import Foundation
import UIKit
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

    private let ref = Database.database().reference()
    let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

    /// スコアを登録する（priority = -score で降順に並ぶようにする）。
    func register(name: String, score: Int) {
        ref.child("scores").child(deviceID).setValue(
            ["name": name, "score": score as NSNumber],
            andPriority: -score
        )
    }

    /// device_id のスコアを 0 にリセット（ローカル全削除時）。
    func reset(name: String) {
        ref.child("scores").child(deviceID).setValue(["name": name, "score": 0])
    }

    /// 全スコアを priority 順で取得し、順位付けした配列を返す。
    /// 併せて自分の順位（見つからなければ 0）と、自分の行の並び順インデックス（無ければ nil）も返す。
    func fetchRanking() async -> (entries: [RankEntry], myRank: Int, myIndex: Int?) {
        // Firebase のコールバックへ渡すため、MainActor 隔離の self を捕捉せずローカルへ退避する。
        let deviceID = self.deviceID
        let query = ref.child("scores").queryOrderedByPriority()
        return await withCheckedContinuation { continuation in
            query.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: RankingService.rank(from: snapshot, deviceID: deviceID))
            } withCancel: { error in
                print(error.localizedDescription)
                continuation.resume(returning: ([], 0, nil))
            }
        }
    }

    /// snapshot を score 降順に並べ、同点は同順位でランク付けする。
    private static func rank(from snapshot: DataSnapshot, deviceID: String) -> (entries: [RankEntry], myRank: Int, myIndex: Int?) {
        guard let values = snapshot.value as? [String: Any] else {
            return ([], 0, nil)
        }

        // (key, score, name) に整形して score 降順にソート。
        let rows: [(key: String, score: Int, name: String)] = values.compactMap { key, value in
            guard let dict = value as? [String: Any],
                  let score = (dict["score"] as? NSNumber)?.intValue else { return nil }
            let rawName = (dict["name"] as? String) ?? ""
            let name = rawName.isEmpty ? "No Name" : rawName
            return (key, score, name)
        }
        .sorted { $0.score > $1.score }

        var entries: [RankEntry] = []
        var myRank = 0
        var myIndex: Int?
        var currentRank = 0
        var previousScore: Int?
        for (index, row) in rows.enumerated() {
            if row.score != previousScore {
                currentRank = index + 1
                previousScore = row.score
            }
            entries.append(RankEntry(rank: currentRank, score: row.score, name: row.name))
            // 同点者がいても、自分の行は device_id で一意に特定する。
            if row.key == deviceID {
                myRank = currentRank
                myIndex = index
            }
        }
        return (entries, myRank, myIndex)
    }
}
