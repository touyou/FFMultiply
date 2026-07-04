//
//  FFColor.swift
//  FFMultiply
//
//  Asset カタログ "FFColors/*.colorset" を型安全な Color として公開する。
//

import SwiftUI

/// 元デザインの FF カラーパレット。Asset 名と 1:1 対応する。
enum FFColor {
    static let blackBackground = Color("FFBlackBackground")
    static let blackReversible = Color("FFBlackReversible")
    static let brown = Color("FFBrown")
    static let darkGray = Color("FFDarkGray")
    static let gray = Color("FFGray")
    static let green = Color("FFGreen")
    static let greenBackground = Color("FFGreenBackground")
    static let lightGrayBackground = Color("FFLightGrayBackground")
    static let red = Color("FFRed")
    static let settingGray = Color("FFSettingGray")
    static let white = Color("FFWhite")
    static let whiteBackground = Color("FFWhiteBackground")
}
