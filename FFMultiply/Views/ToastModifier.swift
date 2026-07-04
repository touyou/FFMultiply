//
//  ToastModifier.swift
//  FFMultiply
//
//  旧 ToastSwift の代替。accepted / failed の短いトーストを Liquid Glass で表示する。
//

import SwiftUI

/// トーストで表示するメッセージ。表示ごとに新しい id を割り当てて再アニメーションさせる。
struct ToastMessage: Equatable {
    let id: UUID
    let text: String

    init(_ text: String) {
        self.id = UUID()
        self.text = text
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: ToastMessage?

    func body(content: Content) -> some View {
        content.overlay(alignment: .center) {
            if let message {
                Text(message.text)
                    .font(.futuraBold(size: 20))
                    .foregroundStyle(FFColor.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .ffGlassCard(cornerRadius: 16)
                    .transition(.opacity.combined(with: .scale))
                    .id(message.id)
                    .task(id: message.id) {
                        // extraShort 相当の短い表示。
                        try? await Task.sleep(for: .milliseconds(700))
                        withAnimation { self.message = nil }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}

extension View {
    /// 中央に短いトーストを表示する。`message` に値をセットすると表示され、自動で消える。
    func toast(_ message: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
