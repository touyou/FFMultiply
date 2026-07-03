//
//  ScoreStore.swift
//  FFMultiply
//
//  SwiftData を用いたローカルスコアの読み書き（ハイスコア / 一覧 / 全削除）。
//

import Foundation
import SwiftData

@MainActor
struct ScoreStore {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// スコア降順の一覧を返す。
    func allScores() -> [ScoreEntry] {
        let descriptor = FetchDescriptor<ScoreEntry>(
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// 現在のハイスコア（無ければ nil）。
    func highScore() -> ScoreEntry? {
        allScores().first
    }

    /// 新しいスコアを保存し、保存した ScoreEntry を返す。
    @discardableResult
    func add(score: Int, date: Date = Date()) -> ScoreEntry {
        let entry = ScoreEntry(date: date, score: score)
        context.insert(entry)
        try? context.save()
        return entry
    }

    /// 全スコアを削除する。
    func deleteAll() {
        try? context.delete(model: ScoreEntry.self)
        try? context.save()
    }
}
