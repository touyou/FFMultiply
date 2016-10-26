//
//  FFConstructor.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import Foundation

// hex enum
enum FNum: Int {
    case zero = 0
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case a = 10
    case b = 11
    case c = 12
    case d = 13
    case e = 14
    case f = 15
}

// problem alias
// 0: left number, 1: right number, 2: answer string
typealias FFProblem = (FNum, FNum, String)

// Convert FNum elements to String
func convertFNum(toStr fnum: FNum) -> String {
    if fnum.rawValue < 10 {
        return String(fnum.rawValue)
    } else {
        var ret: String!
        switch fnum {
        case .a:
            ret = "A"
        case .b:
            ret = "B"
        case .c:
            ret = "C"
        case .d:
            ret = "D"
        case .e:
            ret = "E"
        case .f:
            ret = "F"
        default:
            ret = ""
        }
        return ret
    }
}

// Convert a character to FNum
func convertStr(toFnum str: String) -> FNum? {
    if str.characters.count > 1 {
        return nil
    }
    if let num = Int(str) {
        return FNum(rawValue: num)
    } else {
        switch str {
        case "A":
            return .a
        case "B":
            return .b
        case "C":
            return .c
        case "D":
            return .d
        case "E":
            return .e
        case "F":
            return .f
        default:
            return nil
        }
    }
}

// Convert string representing hex number to Integer
func convertStr(toInt str: String) -> Int {
    var mul = 1
    var ret = 0
    for c in str.characters {
        ret += (convertStr(toFnum: String(c))?.rawValue ?? 0) * mul
        mul *= 16
    }
    return ret
}

// Multiply FNumber
func fTimes(_ a: FNum, _ b: FNum) -> String {
    let temp = a.rawValue * b.rawValue
    if temp >= 16 {
        return convertFNum(toStr: FNum(rawValue: temp / 16)!) + convertFNum(toStr: FNum(rawValue: temp % 16)!)
    } else {
        return convertFNum(toStr: FNum(rawValue: temp)!)
    }
}

// Compare FFProblems
fileprivate func isEqual(_ a: FFProblem, _ b: FFProblem) -> Bool {
    return a.0 == b.0 && a.1 == b.1 && a.2 == b.2
}

// Make some problems
func makeProblem(_ num: Int) -> [FFProblem] {
    var ret: [FFProblem] = []
    for i in 0 ..< num {
        var a = FNum(rawValue: Int(arc4random_uniform(16))) ?? .zero
        var b = FNum(rawValue: Int(arc4random_uniform(16))) ?? .zero
        var ans = fTimes(a, b)
        for _ in 0 ..< 10 {
            var flag = true
            for j in 0 ..< i {
                if isEqual(ret[j], (a, b, ans)) {
                    flag = false
                    break
                }
            }
            if flag {
                break
            } else {
                a = FNum(rawValue: Int(arc4random_uniform(16))) ?? .zero
                b = FNum(rawValue: Int(arc4random_uniform(16))) ?? .zero
                ans = fTimes(a, b)
            }
        }
        ret.append((a, b, ans))
    }
    return ret
}
