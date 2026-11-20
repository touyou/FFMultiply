//
//  AboutView.swift
//  FFMultiply
//
//  設定の「INFO」。バージョン・フィードバック・法務をここにまとめ、設定にはアプリの設定だけを残す。
//

import SwiftUI

struct AboutView: View {
    /// チュートリアルは設定画面の上に重ねて出すので、表示は呼び出し側に任せる
    let onShowTutorial: () -> Void

    var body: some View {
        List {
            Section {
                AboutHeader()
            }

            Section {
                AboutLinkRow(title: "RATE THIS APP", systemImage: "star", destination: AppLinks.writeReview)
                AboutLinkRow(title: "FEEDBACK & BUG REPORTS", systemImage: "envelope", destination: AppLinks.support)
                ShareLink(item: AppLinks.appStore) {
                    Label("SHARE THIS APP", systemImage: "square.and.arrow.up")
                }
            } header: {
                Text("FEEDBACK")
            }

            Section {
                Button(action: onShowTutorial) {
                    Label("HELP", systemImage: "questionmark.circle")
                }
                AboutLinkRow(title: "DEVELOPER", systemImage: "person", destination: AppLinks.developer)
            }

            Section {
                AboutLinkRow(title: "PRIVACY POLICY", systemImage: "hand.raised", destination: AppLinks.privacy)
                // EEA・英国など、広告の同意を変更できる必要がある地域でだけ出す。
                if ConsentManager.shared.isPrivacyOptionsRequired {
                    Button {
                        Task {
                            await ConsentManager.shared.presentPrivacyOptionsForm()
                            AdManager.shared.startIfAllowed()
                        }
                    } label: {
                        Label("PRIVACY SETTINGS", systemImage: "slider.horizontal.3")
                    }
                }
                NavigationLink {
                    LicensesView()
                } label: {
                    Label("Open Source Licenses", systemImage: "doc.text")
                }
            }
        }
        .tint(FFColor.green)
        .scrollContentBackground(.hidden)
        .background(FFColor.settingGray.ignoresSafeArea())
        .navigationTitle("INFO")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AboutHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            Text(verbatim: "FFMultiplier")
                .font(.futuraBold(size: 24))
                .foregroundStyle(FFColor.blackReversible)
            Text("Version \(AppLinks.version)")
                .font(.futuraMedium(size: 14))
                .foregroundStyle(FFColor.darkGray)
            Text("Made by one developer in Japan.")
                .font(.footnote)
                .foregroundStyle(FFColor.darkGray)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

/// アプリの外（Safari・App Store）へ出る行。押すと外へ出ることが分かるよう矢印を付ける
private struct AboutLinkRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

enum AppLinks {
    static let appStore = URL(string: "https://apps.apple.com/app/id1151801381")!
    static let writeReview = URL(string: "https://apps.apple.com/app/id1151801381?action=write-review")!
    static let support = URL(string: "https://touyou.dev/ffmultiplier/support")!
    static let privacy = URL(string: "https://touyou.dev/ffmultiplier/privacy")!
    static let developer = URL(string: "https://touyou.dev")!

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(short) (\(build))"
    }
}
