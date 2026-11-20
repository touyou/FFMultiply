//
//  LicensesView.swift
//  FFMultiply
//
//  同梱しているライブラリとフォントのライセンス(Licenses.txt)。
//

import SwiftUI

struct LicensesView: View {
    // 依存やフォントを足したら Licenses.txt も更新する
    private let text: String = {
        guard let url = Bundle.main.url(forResource: "Licenses", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return text
    }()

    var body: some View {
        ScrollView {
            Text(verbatim: text)
                .font(.footnote.monospaced())
                .foregroundStyle(FFColor.darkGray)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
        }
        .background(FFColor.settingGray.ignoresSafeArea())
        .navigationTitle("Open Source Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}
