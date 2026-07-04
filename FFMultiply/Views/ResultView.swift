//
//  ResultView.swift
//  FFMultiply
//
//  ゲーム終了時のリザルトカード。UI層は Liquid Glass カード、得点はブランド配色で大きく表示。
//  元デザインに寄せすぎず、SwiftUI らしい自然なレイアウトにする。
//

import SwiftUI

struct ResultView: View {
    let score: Int
    let isHighScore: Bool
    let onExit: () -> Void

    private let shareURL = URL(string: "https://itunes.apple.com/us/app/ffmultiplier/id1151801381?l=ja&ls=1&mt=8")!
    private var shareText: String {
        "I got \(score) points! Let's play FFMultiplier with me! #FFMultiplier"
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Result")
                .font(.futuraBold(size: 22))
                .foregroundStyle(.primary)

            if isHighScore {
                // 明るいガラス下地でも読めるよう、赤カプセル+白文字のバッジにする。
                Label("High Score", systemImage: "crown.fill")
                    .font(.futuraBold(size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(FFColor.red, in: .capsule)
            }

            // 得点はゲーム画面と同じ「黒地に緑セブンセグ」チップで高コントラストに。
            Text(String(score))
                .font(.dseg7(size: 72))
                .foregroundStyle(FFColor.green)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(FFColor.blackBackground, in: .rect(cornerRadius: 20))

            HStack(spacing: 12) {
                ShareLink(item: shareURL, message: Text(shareText)) {
                    Text("SHARE").frame(maxWidth: .infinity)
                }
                .ffButtonStyle(prominent: true, tint: FFColor.green)

                Button(action: onExit) {
                    Text("EXIT").frame(maxWidth: .infinity)
                }
                .ffButtonStyle(tint: FFColor.gray)
            }
            .controlSize(.large)
        }
        .padding(28)
        .frame(maxWidth: 320)
        .ffGlassCard(cornerRadius: 28)
        .padding(.horizontal, 24)
    }
}
