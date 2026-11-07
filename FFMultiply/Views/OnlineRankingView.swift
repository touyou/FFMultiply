//
//  OnlineRankingView.swift
//  FFMultiply
//
//  オンラインランキング。Top50 / Nearby セグメント、SHARE / REGISTER、自分の順位表示。
//

import SwiftUI
import AppIntents

struct OnlineRankingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ScoreService.self) private var scoreService

    @State private var vm = OnlineRankingViewModel()
    @State private var showNamePrompt = false
    @State private var nameInput = ""

    private let shareURL = URL(string: "https://itunes.apple.com/us/app/ffmultiplier/id1151801381?l=ja&ls=1&mt=8")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("", selection: $vm.isTop) {
                    Text("Top50").tag(true)
                    Text("Nearby").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                List(vm.displayedEntries) { entry in
                    Text("\(entry.rank). \(entry.score) points\n\t \(entry.name)")
                        .font(.futuraMedium(size: 16))
                        .foregroundStyle(FFColor.white)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .overlay {
                    if vm.entries.isEmpty {
                        ContentUnavailableView("No Data", systemImage: "trophy")
                            .foregroundStyle(FFColor.white)
                    }
                }

                Text("Your Rank: \(vm.myRank)")
                    .accessibilityIdentifier("yourRankLabel")
                    .font(.futuraMedium(size: 14))
                    .foregroundStyle(Color(white: 0.33))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(FFColor.whiteBackground)

                RegisterScoreButton(hasPlayerName: !scoreService.playerName.isEmpty) {
                    nameInput = ""
                    showNamePrompt = true
                }
                .ffButtonStyle(prominent: true, tint: FFColor.blackReversible)
                .controlSize(.large)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FFColor.greenBackground.ignoresSafeArea())
            // 見た目のタイトルは principal の Futura だが、システムが使うタイトルも渡しておく。
            .navigationTitle("Online Ranking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Online Ranking")
                        .font(.futuraBold(size: 17))
                        .foregroundStyle(FFColor.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    FFCloseButton { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareURL, message: Text(shareText)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                .ffLowVisibilityPriority()
            }
        }
        // 登録したら（Siri からでも）読み直す。
        .task(id: scoreService.lastRegistration) { await vm.load() }
        .alert("register name", isPresented: $showNamePrompt) {
            TextField("user name", text: $nameInput)
            Button("OK") {
                let name = RankingService.normalizedName(nameInput)
                guard !name.isEmpty else { return }
                scoreService.playerName = name
                Task { try? await scoreService.registerHighScore() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("please set your username")
        }
    }

    private var shareText: String {
        "My rank is \(vm.myRank)! Let's play FFMultiplier with me! #FFMultiplier"
    }
}

/// 名前があれば Siri と同じ Intent で登録し、無ければ名前の入力を促す。
private struct RegisterScoreButton: View {
    let hasPlayerName: Bool
    let askName: () -> Void

    var body: some View {
        if hasPlayerName {
            Button(intent: RegisterHighScoreIntent()) { RegisterScoreLabel() }
        } else {
            Button(action: askName) { RegisterScoreLabel() }
        }
    }
}

private struct RegisterScoreLabel: View {
    var body: some View {
        Text("REGISTER MY SCORE").frame(maxWidth: .infinity)
    }
}
