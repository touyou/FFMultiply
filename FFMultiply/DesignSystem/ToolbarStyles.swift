//
//  ToolbarStyles.swift
//  FFMultiply
//
//  ツールバー項目の共通部品。iPhone Duo ではツールバー項目が画面端の縦のバーへ移り、
//  あふれた項目はタイトル付きでオーバーフローメニューに入るため、
//  role / タイトル / あふれる順序をここで揃える。
//  role の `.close` / `.confirm` は iOS 26+、`visibilityPriority` は iOS 27+ の API のため、
//  デプロイ先 iOS 18 では role なし・優先度指定なしにフォールバックする。
//

import SwiftUI

/// sheet などを閉じるボタン。画像だけの見た目でもタイトル「Close」を持つ。
struct FFCloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button("Close", systemImage: "xmark", role: .close, action: action)
        } else {
            Button("Close", systemImage: "xmark", action: action)
        }
    }
}

/// 編集内容を確定するボタン（Save など）。
struct FFConfirmButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        if #available(iOS 26, *) {
            Button(title, role: .confirm, action: action)
        } else {
            Button(title, action: action)
        }
    }
}

extension ToolbarContent {
    /// 幅が足りないときに先にオーバーフローメニューへ回してよい項目に付ける。
    @ToolbarContentBuilder
    func ffLowVisibilityPriority() -> some ToolbarContent {
        if #available(iOS 27, *) {
            self.visibilityPriority(.low)
        } else {
            self
        }
    }
}
