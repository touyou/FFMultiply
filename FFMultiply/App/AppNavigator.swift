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

    /// 結果画面を開いたまま始めても、新しいゲームになるようにする。
    func startTimeAttack() {
        if isPlayingTimeAttack {
            timeAttackID = UUID()
        } else {
            isPlayingTimeAttack = true
        }
    }
}
