//
//  FFProblem.swift
//  FFMultiply
//
//  16 進の九九（0〜F × 0〜F）の 1 問と、その出題セット。
//

import Foundation

/// 16 進の 1 桁。
enum FNum: Int, CaseIterable {
    case zero = 0, one, two, three, four, five, six, seven
    case eight, nine, a, b, c, d, e, f

    /// 表示用の 1 文字（0〜9, A〜F）。
    var symbol: String { String(rawValue, radix: 16, uppercase: true) }
}

/// 1 問。`answer` は積を大文字の 16 進で書いたもの（例: F × F = "E1"）。
struct FFProblem: Equatable {
    let left: FNum
    let right: FNum

    var answer: String { String(left.rawValue * right.rawValue, radix: 16, uppercase: true) }

    static func random() -> FFProblem {
        FFProblem(left: FNum.allCases.randomElement()!, right: FNum.allCases.randomElement()!)
    }

    /// `count` 問を作る。組み合わせは 256 通りしかないので、既出の問題は 10 回まで
    /// 引き直し、それでも重なればそのまま入れる。
    static func makeSet(count: Int) -> [FFProblem] {
        var problems: [FFProblem] = []
        problems.reserveCapacity(count)
        for _ in 0..<count {
            var problem = random()
            var retries = 0
            while retries < 10, problems.contains(problem) {
                problem = random()
                retries += 1
            }
            problems.append(problem)
        }
        return problems
    }
}
