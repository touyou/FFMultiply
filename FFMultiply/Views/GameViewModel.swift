//
//  GameViewModel.swift
//  FFMultiply
//
//  16進掛け算ゲームの出題・入力・採点・コンボ・タイマー状態を管理する。
//  旧 GameViewController のロジックを踏襲。
//

import Foundation
import Observation

@Observable
@MainActor
final class GameViewModel {
    // MARK: 状態
    private(set) var problems: [FFProblem] = []
    private(set) var current: FFProblem?
    private(set) var input: String = ""
    private(set) var score: Int = 0
    private(set) var combo: Int = 0
    private(set) var remaining: Int = 60
    private(set) var isFinished: Bool = false
    var toast: ToastMessage?

    // MARK: スコア定数（旧実装踏襲）
    private let limitTime = 60
    private let pointsAccepted = 10
    private let pointsFailed = -5
    private let pointsCombo = 5
    private let maxComboBonus = 15

    // MARK: 表示用
    /// 入力中の値。空なら "--"。
    var displayInput: String { input.isEmpty ? "--" : input }
    var leftText: String { current.map { convertFNum(toStr: $0.0) } ?? "" }
    var rightText: String { current.map { convertFNum(toStr: $0.1) } ?? "" }
    var scoreText: String { String(score) }
    var timeText: String { String(remaining) }

    // MARK: ゲーム進行
    func start() {
        problems = makeProblem(1000)
        remaining = limitTime
        score = 0
        combo = 0
        isFinished = false
        input = ""
        pickProblem()
    }

    private func pickProblem() {
        guard !problems.isEmpty else { return }
        current = problems.popLast()
    }

    /// 数字キー入力（最大 2 文字）。
    func tapNumber(_ value: FNum) {
        guard input.count < 2 else { return }
        input += convertFNum(toStr: value)
    }

    /// 1 文字削除。
    func delete() {
        guard !input.isEmpty else { return }
        input.removeLast()
    }

    /// 解答判定。正誤に応じてスコア・コンボを更新し、次の問題へ。
    func done() {
        guard let current else { return }
        let accepted = current.2 == input
        toast = ToastMessage(accepted ? "accepted" : "failed")
        if accepted {
            score += pointsAccepted + min(pointsCombo * (combo / 5), maxComboBonus)
            combo += 1
        } else {
            score += pointsFailed
            combo = 0
        }
        input = ""
        pickProblem()
    }

    /// 1 秒経過。0 になったら終了する。
    func tick() {
        guard !isFinished else { return }
        remaining -= 1
        if remaining <= 0 {
            remaining = 0
            isFinished = true
        }
    }
}
