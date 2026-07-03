//
//  OnlineRankingView.swift
//  FFMultiply
//
//  オンラインランキング。Top50 / Nearby セグメント、SHARE / REGISTER、自分の順位表示。
//

import SwiftUI
import SwiftData

struct OnlineRankingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var vm = OnlineRankingViewModel()
    @State private var showNamePrompt = false
    @State private var nameInput = ""

    private let storage = UserDefaults.standard
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
                    .font(.futuraMedium(size: 14))
                    .foregroundStyle(Color(white: 0.33))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(FFColor.whiteBackground)

                Button {
                    register()
                } label: {
                    Text("REGISTER MY SCORE").frame(maxWidth: .infinity)
                }
                .ffButtonStyle(prominent: true, tint: FFColor.blackReversible)
                .controlSize(.large)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FFColor.greenBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Online Ranking")
                        .font(.futuraBold(size: 17))
                        .foregroundStyle(FFColor.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareURL, message: Text(shareText)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task { await vm.load() }
        .alert("register name", isPresented: $showNamePrompt) {
            TextField("user name", text: $nameInput)
            Button("OK") {
                guard !nameInput.isEmpty else { return }
                storage.set(nameInput, forKey: "playername")
                registerScore(name: nameInput)
                Task { await vm.load() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("please set your username")
        }
    }

    private var shareText: String {
        "My rank is \(vm.myRank)! Let's play FFMultiplier with me! #FFMultiplier"
    }

    /// 自分の最高スコアを登録する。名前未設定なら入力を促す。
    private func register() {
        if let name = storage.object(forKey: "playername") as? String, !name.isEmpty {
            registerScore(name: name)
            Task { await vm.load() }
        } else {
            nameInput = ""
            showNamePrompt = true
        }
    }

    private func registerScore(name: String) {
        guard let best = ScoreStore(context: modelContext).highScore() else { return }
        RankingService.shared.register(name: name, score: best.score)
    }
}
