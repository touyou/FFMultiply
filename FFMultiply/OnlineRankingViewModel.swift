//
//  OnlineRankingViewModel.swift
//  FFMultiply
//
//  オンラインランキングの取得と表示モード（Top50 / Nearby）を管理する。
//

import Foundation
import Observation

@Observable
@MainActor
final class OnlineRankingViewModel {
    var entries: [RankEntry] = []
    var myRank: Int = 0
    var isTop = true

    private let service = RankingService.shared

    /// ランキングを取得する。
    func load() async {
        let result = await service.fetchRanking()
        entries = result.entries
        myRank = result.myRank
    }

    /// 表示対象。Top50 は上位 50 件、Nearby は自分の周辺 50 件。
    var displayedEntries: [RankEntry] {
        if isTop {
            return Array(entries.prefix(50))
        }
        guard let myIndex = entries.firstIndex(where: { $0.rank == myRank }), myRank > 0 else {
            return Array(entries.prefix(50))
        }
        let lower = max(0, myIndex - 25)
        let upper = min(entries.count, lower + 50)
        return Array(entries[lower..<upper])
    }
}
