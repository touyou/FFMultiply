//
//  FFFont.swift
//  FFMultiply
//
//  Futura / DSEG7 のフォントヘルパー。
//  DSEG7 は Info.plist の UIAppFonts に "DSEG7ClassicMini-Bold.ttf" を登録すること。
//

import SwiftUI

extension Font {
    /// セブンセグ風フォント（タイマー・問題・入力表示・キーパッド等）。
    static func dseg7(size: CGFloat) -> Font {
        .custom("DSEG7ClassicMini-Bold", size: size)
    }

    /// 各画面タイトル用（Futura-Bold）。
    static func futuraBold(size: CGFloat) -> Font {
        .custom("Futura-Bold", size: size)
    }

    /// ボタン・ラベル用（Futura-Medium）。
    static func futuraMedium(size: CGFloat) -> Font {
        .custom("Futura-Medium", size: size)
    }
}
