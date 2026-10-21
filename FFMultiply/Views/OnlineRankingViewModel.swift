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
    /// 自分の行の並び順インデックス（未登録なら nil）。Nearby の中心に使う。
    var myIndex: Int?
    var isTop = true

    /// 撮影用の固定データで動かしている間は Firebase を起動しないため、使うときに初めて参照する。
    private var service: RankingService { RankingService.shared }

    /// ランキングを取得する。
    func load() async {
        if ScreenshotFixture.isActive {
            entries = ScreenshotFixture.ranking
            myRank = ScreenshotFixture.myRank
            myIndex = entries.firstIndex { $0.rank == ScreenshotFixture.myRank }
            return
        }
        let result = await service.fetchRanking()
        entries = result.entries
        myRank = result.myRank
        myIndex = result.myIndex
    }

    /// 表示対象。Top50 は上位 50 件、Nearby は自分の周辺 50 件。
    var displayedEntries: [RankEntry] {
        if isTop {
            return Array(entries.prefix(50))
        }
        // 同点者がいても自分自身を中心にするため、rank 値でなく device_id で特定した実インデックスを使う。
        guard let myIndex else {
            return Array(entries.prefix(50))
        }
        let lower = max(0, myIndex - 25)
        let upper = min(entries.count, lower + 50)
        return Array(entries[lower..<upper])
    }
}
