//
//  TutorialView.swift
//  FFMultiply
//
//  チュートリアルのポップアップ。app icon + tutorial1..6 をページングで表示する。
//

import SwiftUI

struct TutorialView: View {
    let onExit: () -> Void

    @State private var selection = 0
    private let images = ["tutorial1", "tutorial2", "tutorial3", "tutorial4", "tutorial5", "tutorial6"]

    var body: some View {
        VStack(spacing: 12) {
            Image("ffmultiicon")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .clipShape(.rect(cornerRadius: 12))
                .padding(.top, 12)

            TabView(selection: $selection) {
                ForEach(images.indices, id: \.self) { index in
                    Image(images[index])
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 8)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxHeight: 320)

            HStack(spacing: 16) {
                Button {
                    if selection > 0 { withAnimation { selection -= 1 } }
                } label: {
                    Text("👈").font(.system(size: 24))
                }
                .disabled(selection == 0)

                Button("EXIT", action: onExit)
                    .ffButtonStyle(prominent: true, tint: FFColor.green)
                    .controlSize(.large)

                Button {
                    if selection < images.count - 1 { withAnimation { selection += 1 } }
                } label: {
                    Text("👉").font(.system(size: 24))
                }
                .disabled(selection == images.count - 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        // 固定サイズだとウインドウが小さいとき（iPhone Duo の画面切替・リサイズ時など）に
        // はみ出すため、上限サイズだけ決めて表示領域に合わせて縮むようにする。
        .frame(maxWidth: 320, maxHeight: 483)
        .background(FFColor.whiteBackground)
        .ffGlassCard(cornerRadius: 20)
        .padding(24)
    }
}
