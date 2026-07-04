//
//  RealmMigration.swift
//  FFMultiply
//
//  初回起動時に、旧 Realm(`Score`) のローカルスコアを SwiftData(`ScoreEntry`) へ一度きり移行する。
//  移行完了は UserDefaults フラグで管理し、二重移行を防ぐ。
//  移行が終わり実配布で十分に行き渡ったら realm-swift 依存ごと本ファイルと LegacyRealmScore を削除する。
//

import Foundation
import SwiftData
import RealmSwift

enum RealmMigration {
    private static let migratedKey = "didMigrateRealmToSwiftData"

    /// 旧 Realm データを SwiftData へ移行する（未実施なら 1 回だけ）。
    @MainActor
    static func migrateIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migratedKey) else { return }

        do {
            let realm = try Realm()
            let legacyScores = realm.objects(Score.self)
            let store = ScoreStore(context: context)
            for legacy in legacyScores {
                store.add(score: legacy.score, date: legacy.date as Date)
            }
        } catch {
            // Realm ファイルが存在しない / 読めない場合も移行済み扱いにして再試行しない。
            print("Realm migration skipped: \(error.localizedDescription)")
        }

        defaults.set(true, forKey: migratedKey)
    }
}
