//
//  GlassStyles.swift
//  FFMultiply
//
//  Liquid Glass 共通のスタイル / modifier。
//  Liquid Glass は iOS 26+ の API のため、デプロイ先 iOS 18 では material フォールバックする。
//  Glass API の直接使用は本ファイルに集約する。
//

import SwiftUI

extension View {
    /// ポップアップカード（Result / Tutorial）や Toast 用の角丸ガラスカード。
    @ViewBuilder
    func ffGlassCard(cornerRadius: CGFloat = 20) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.regularMaterial, in: .rect(cornerRadius: cornerRadius))
        }
    }

    /// 標準の Liquid Glass ボタンスタイル。iOS 26 では `.glass` / `.glassProminent`、
    /// iOS 18 では `.bordered` / `.borderedProminent` にフォールバックする。
    @ViewBuilder
    func ffButtonStyle(prominent: Bool = false, tint: Color) -> some View {
        if #available(iOS 26, *) {
            if prominent {
                self.buttonStyle(.glassProminent).tint(tint)
            } else {
                self.buttonStyle(.glass).tint(tint)
            }
        } else {
            if prominent {
                self.buttonStyle(.borderedProminent).tint(tint)
            } else {
                self.buttonStyle(.bordered).tint(tint)
            }
        }
    }
}
