//
//  LicensesView.swift
//  FFMultiply
//
//  同梱しているライブラリとフォントのライセンス。一覧から選ぶと全文を出す。
//

import SwiftUI

struct LicensesView: View {
    // 依存やフォントを足したら Licenses.txt も更新する
    private let entries = LicenseEntry.bundled

    var body: some View {
        List(entries) { entry in
            NavigationLink {
                LicenseDetailView(entry: entry)
            } label: {
                LicenseRow(entry: entry)
            }
        }
        .tint(FFColor.green)
        .scrollContentBackground(.hidden)
        .background(FFColor.settingGray.ignoresSafeArea())
        .navigationTitle("Open Source Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LicenseRow: View {
    let entry: LicenseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: entry.name)
                .foregroundStyle(FFColor.blackReversible)
            Text(verbatim: entry.license)
                .font(.footnote)
                .foregroundStyle(FFColor.darkGray)
        }
    }
}

private struct LicenseDetailView: View {
    let entry: LicenseEntry

    var body: some View {
        ScrollView {
            Text(verbatim: entry.body)
                .font(.footnote.monospaced())
                .foregroundStyle(FFColor.darkGray)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
        }
        .background(FFColor.settingGray.ignoresSafeArea())
        .navigationTitle(Text(verbatim: entry.name))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Licenses.txt の 1 件。件ごとに `=====` だけの行で区切り、1 行目を名前、2 行目をライセンス名、残りを本文として読む
struct LicenseEntry: Identifiable {
    let name: String
    let license: String
    let body: String

    var id: String { name }

    static let bundled: [LicenseEntry] = {
        guard let url = Bundle.main.url(forResource: "Licenses", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return parse(text)
    }()

    static func parse(_ text: String) -> [LicenseEntry] {
        var blocks: [[String]] = [[]]
        for line in text.components(separatedBy: .newlines) {
            if line.count >= 5, line.allSatisfy({ $0 == "=" }) {
                blocks.append([])
            } else {
                blocks[blocks.count - 1].append(line)
            }
        }
        return blocks.compactMap { lines in
            let lines = Array(lines.drop(while: { $0.trimmingCharacters(in: .whitespaces).isEmpty }))
            guard lines.count >= 2 else { return nil }
            let body = lines.dropFirst(2).joined(separator: "\n").trimmingCharacters(in: .newlines)
            return LicenseEntry(name: lines[0], license: lines[1], body: body)
        }
    }
}
