//
//  AppNavigator.swift
//  FFMultiply
//
//  画面遷移の状態。App Intent からも書けるよう、App と AppDependencyManager の
//  両方に同じインスタンスを渡す。
//

import Observation

@Observable
@MainActor
final class AppNavigator {
    /// タイムアタックを全画面で表示中か。
    var isPlayingTimeAttack = false
}
