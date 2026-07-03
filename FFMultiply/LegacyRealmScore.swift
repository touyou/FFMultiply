//
//  LegacyRealmScore.swift
//  FFMultiply
//
//  旧 Realm データ移行専用のモデル。旧 `ScoreModel.swift` の `Score` と同一スキーマ。
//  Realm はクラス名をテーブル名として使うため、既存データを読むにはクラス名を `Score` のまま保つ必要がある。
//  移行完了後（realm-swift 依存を外す段階）に、この 1 ファイルごと削除する。
//

import Foundation
import RealmSwift

final class Score: Object {
    @objc dynamic var date = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var score: Int = 0
}
