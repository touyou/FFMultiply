//
//  ScoreEntry.swift
//  FFMultiply
//
//  ローカルスコアの永続化モデル（SwiftData）。旧 Realm `Score` の後継。
//

import Foundation
import SwiftData

@Model
final class ScoreEntry {
    var date: Date
    var score: Int

    init(date: Date = Date(), score: Int = 0) {
        self.date = date
        self.score = score
    }
}
