//
//  AppNavigator.swift
//  FFMultiply
//
//  画面遷移の状態。App Intent からも書けるよう、App と AppDependencyManager の
//  両方に同じインスタンスを渡す。
//

import Foundation
import Observation

@Observable
@MainActor
final class AppNavigator {
    /// タイムアタックを全画面で表示中か。
    var isPlayingTimeAttack = false
    /// GameView の identity。変えると表示中のゲーム（結果画面を含む）が作り直される。
    private(set) var timeAttackID = UUID()

    /// ホームから開くシート。Intent からも開けるよう、画面の @State ではなくここに置く。
    enum Sheet: String, Identifiable {
        case localScore, onlineRanking, settings
        var id: String { rawValue }
    }

    var sheet: Sheet?

    /// シートを開く。全画面のゲームの上にはシートを出せないので、遊んでいる最中なら閉じてから開く。
    func show(_ sheet: Sheet) async {
        if isPlayingTimeAttack {
            isPlayingTimeAttack = false
            try? await Task.sleep(for: .milliseconds(600))
        }
        // 待っている間に新しいゲームが始まったら、そちらを優先してシートは出さない。
        guard !isPlayingTimeAttack else { return }
        self.sheet = sheet
    }

    /// 結果画面を開いたまま始めても、新しいゲームになるようにする。
    func startTimeAttack() {
        if isPlayingTimeAttack {
            timeAttackID = UUID()
        } else {
            isPlayingTimeAttack = true
        }
    }
}
