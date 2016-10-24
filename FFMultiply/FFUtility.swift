//
//  FFConstructor.swift
//  FFMultiply
//
//  Created by 藤井陽介 on 2016/10/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import Foundation

internal enum FNum: Int {
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

internal func convertFNum(toStr fnum: FNum) -> String {
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

internal func convertStr(toFnum str: String) -> FNum? {
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

internal func convertStr(toInt str: String) -> Int {
    var mul = 1
    var ret = 0
    for c in str.characters {
        ret += (convertStr(toFnum: String(c))?.rawValue ?? 0) * mul
        mul *= 16
    }
    return ret
}

internal func fTimes(_ a: FNum, _ b: FNum) -> String {
    let temp = a.rawValue * b.rawValue
    if temp >= 16 {
        return convertFNum(toStr: FNum(rawValue: temp / 16)!) + convertFNum(toStr: FNum(rawValue: temp % 16)!)
    } else {
        return convertFNum(toStr: FNum(rawValue: temp)!)
    }
}
