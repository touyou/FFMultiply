//
//  SettingsView.swift
//  FFMultiply
//
//  設定画面。UI層(ツールバー/ボタン)は Liquid Glass、コンテンツ層は FF ブランド(settingGray)。
//

import SwiftUI
import AppIntents

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ScoreService.self) private var scoreService

    @State private var name = ""
    @State private var showTutorial = false
    @State private var showRankingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("USER NAME")
                        .font(.futuraBold(size: 14))
                        .foregroundStyle(FFColor.darkGray)
                    TextField("user name", text: $name)
                        .font(.futuraMedium(size: 22))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 18)
                        .frame(height: 56)
                        .background(FFColor.whiteBackground, in: .rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(FFColor.gray, lineWidth: 1)
                        )
                }

                Button {
                    showTutorial = true
                } label: {
                    Label("HELP", systemImage: "questionmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .ffButtonStyle(tint: FFColor.green)
                .controlSize(.large)

                // EEA・英国など、広告の同意を変更できる必要がある地域でだけ出す。
                if ConsentManager.shared.isPrivacyOptionsRequired {
                    Button {
                        Task {
                            await ConsentManager.shared.presentPrivacyOptionsForm()
                            AdManager.shared.startIfAllowed()
                        }
                    } label: {
                        Label("PRIVACY SETTINGS", systemImage: "hand.raised")
                            .frame(maxWidth: .infinity)
                    }
                    .ffButtonStyle(tint: FFColor.darkGray)
                    .controlSize(.large)
                }

                Button(role: .destructive) {
                    showRankingDeleteConfirm = true
                } label: {
                    Label("DELETE FROM RANKING", systemImage: "person.crop.circle.badge.minus")
                        .frame(maxWidth: .infinity)
                }
                .ffButtonStyle(tint: FFColor.red)
                .controlSize(.large)

                Spacer()

                AdBannerView()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FFColor.settingGray.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    FFConfirmButton("Save") {
                        scoreService.setPlayerName(name)
                        dismiss()
                    }
                }
            }
        }
        .onAppear { name = scoreService.playerName }
        // ランキングから抜けると名前も消える（Siri から抜けたときも入力欄を合わせる）。
        .onChange(of: scoreService.playerName) { _, newName in name = newName }
        .alert("Delete from ranking", isPresented: $showRankingDeleteConfirm) {
            Button("Delete", role: .destructive, intent: LeaveRankingNowIntent())
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your name and scores will be removed from the online ranking, and your user name will be cleared. Nothing is sent to the ranking until you set a user name again.")
        }
        .alert("Couldn't delete from ranking", isPresented: Bindable(scoreService).rankingDeleteFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your connection and try again.")
        }
        .overlay {
            if showTutorial {
                ZStack {
                    FFColor.blackReversible.opacity(0.3).ignoresSafeArea()
                    TutorialView { showTutorial = false }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showTutorial)
    }
}
