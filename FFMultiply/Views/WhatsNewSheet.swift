import SwiftUI

/// 版ごとの新機能。新機能のある版を出すときは先頭に足す（修正だけの版は足さない）。
/// アップデートした人にはその版のお知らせを起動時に一度だけ出し、情報の「新機能」から過去の版も開き直せる
enum WhatsNew {
    struct Item: Identifiable {
        let systemImage: String
        let title: LocalizedStringKey
        let message: LocalizedStringKey
        var id: String { systemImage }
    }

    struct Release: Identifiable {
        let version: String
        let greeting: LocalizedStringKey
        let items: [Item]
        var id: String { version }
    }

    @MainActor static let releases: [Release] = []

    /// 起動時に出すお知らせ。`prepareOnLaunch()` が決める
    @MainActor private(set) static var pending: Release?

    /// 起動時に 1 回だけ呼ぶ。新機能の無い版でも呼ぶ（新しく入れた人は、ここでこの版を見終えたことになる）
    @MainActor static func prepareOnLaunch(defaults: UserDefaults = .standard) {
        // 前の版から使っている人は、レビュー依頼のために記録している最初の起動日で見分ける（記録より前に呼ぶ）
        let isReturning = defaults.object(forKey: "reviewFirstLaunchDate") != nil
        let shows = AppUpdate.shouldShowWhatsNew(hasExistingData: isReturning, defaults: defaults)
        pending = shows ? releases.first { $0.version == AppUpdate.currentVersion } : nil
    }
}

/// アップデート後に新機能のお知らせを出すかを決める。
/// 出すのはアップデートした人だけで、新しく入れた人には出さない。見終えた版を覚えて、同じ版では二度と出さない
enum AppUpdate {
    private static let seenVersionKey = "whatsNewSeenVersion"

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    static func shouldShowWhatsNew(
        hasExistingData: Bool, current: String = currentVersion, defaults: UserDefaults = .standard
    ) -> Bool {
        let seen = defaults.string(forKey: seenVersionKey)
        let shows = isUpdate(from: seen, to: current, hasExistingData: hasExistingData)
        // 新しく入れた人は、この版を見終えたことにしておく（次のアップデートで出す）
        if seen == nil, !shows { markSeen(current: current, defaults: defaults) }
        return shows
    }

    /// お知らせを閉じたら呼ぶ。閉じる前にアプリを終えた人には、次の起動でもう一度出す
    static func markSeen(current: String = currentVersion, defaults: UserDefaults = .standard) {
        defaults.set(current, forKey: seenVersionKey)
    }

    static func isUpdate(from previous: String?, to current: String, hasExistingData: Bool) -> Bool {
        guard let previous else { return hasExistingData }
        return previous.compare(current, options: .numeric) == .orderedAscending
    }
}

extension View {
    /// アプリの一番外側の画面に付ける。`WhatsNew.prepareOnLaunch()` が決めたお知らせを出す
    func whatsNewOnUpdate() -> some View {
        modifier(WhatsNewOnUpdate())
    }
}

private struct WhatsNewOnUpdate: ViewModifier {
    @State private var release = WhatsNew.pending

    func body(content: Content) -> some View {
        content
            .sheet(item: $release, onDismiss: { AppUpdate.markSeen() }) { release in
                WhatsNewSheet(release: release)
            }
    }
}

struct WhatsNewSheet: View {
    let release: WhatsNew.Release
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text("What's New in FFMultiplier")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text("Version \(release.version)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(release.greeting)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(release.items) { item in
                            WhatsNewRow(item: item)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 48)
                .padding(.bottom, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: 496)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .tint(FFColor.green)
    }
}

private struct WhatsNewRow: View {
    let item: WhatsNew.Item

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: item.systemImage)
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// 情報の「新機能」。版を選ぶと、そのときのお知らせをもう一度出す
struct WhatsNewHistoryView: View {
    @State private var selection: WhatsNew.Release?

    var body: some View {
        List(WhatsNew.releases) { release in
            Button {
                selection = release
            } label: {
                WhatsNewHistoryRow(release: release)
            }
        }
        .navigationTitle("WHAT'S NEW")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .tint(FFColor.green)
        .scrollContentBackground(.hidden)
        .background(FFColor.settingGray.ignoresSafeArea())
        .sheet(item: $selection) { release in
            WhatsNewSheet(release: release)
        }
    }
}

private struct WhatsNewHistoryRow: View {
    let release: WhatsNew.Release

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Version \(release.version)")
                    .font(.headline.monospacedDigit())
                // 見出しを並べて、開く前に中身の見当がつくようにする
                HStack(spacing: 0) {
                    ForEach(Array(release.items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 { Text(verbatim: " · ") }
                        Text(item.title)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}
