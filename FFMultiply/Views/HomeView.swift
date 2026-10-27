//
//  HomeView.swift
//  FFMultiply
//
//  ホーム画面。key_visual と 4 つのアクション、最下部にバナー広告。
//  初回起動時はチュートリアルを表示する。
//

import SwiftUI
import AppIntents

struct HomeView: View {
    @Environment(AppNavigator.self) private var navigator
    @State private var showLocalScore = false
    @State private var showOnlineRanking = false
    @State private var showSettings = false
    @State private var showTutorial = false

    private let storage = UserDefaults.standard

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 24)
                
                Image("key_visual")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .padding(.horizontal, 40)
                    .padding(.top, 32)

                Spacer(minLength: 24)

                VStack(spacing: 14) {
                    // Siri から始めたときと同じ経路を通す。
                    Button(intent: StartTimeAttackIntent()) {
                        Text("time attack").frame(maxWidth: .infinity)
                    }
                    .ffButtonStyle(prominent: true, tint: FFColor.green)
                    .accessibilityIdentifier("timeAttackButton")
                    menuButton("local score", prominent: false) { showLocalScore = true }
                        .accessibilityIdentifier("localScoreButton")
                    menuButton("online ranking", prominent: false) { showOnlineRanking = true }
                        .accessibilityIdentifier("onlineRankingButton")
                    menuButton("settings", prominent: false) { showSettings = true }
                        .accessibilityIdentifier("settingsButton")
                }
                .controlSize(.large)
                .padding(.horizontal, 40)

                Spacer(minLength: 24)

                AdBannerView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FFColor.white.ignoresSafeArea())
        }
        .fullScreenCover(isPresented: Bindable(navigator).isPlayingTimeAttack) {
            GameView()
        }
        .sheet(isPresented: $showLocalScore) {
            LocalScoreView()
        }
        .sheet(isPresented: $showOnlineRanking) {
            OnlineRankingView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
        .onChange(of: navigator.isPlayingTimeAttack) { _, isPlaying in
            // シートの上には全画面カバーを出せない。Siri から始めたときに開いていたシートは閉じて、
            // 閉じ終わってから出し直す（フラグが true のまま残るとボタンが効かなくなる）。
            guard isPlaying, showLocalScore || showOnlineRanking || showSettings else { return }
            showLocalScore = false
            showOnlineRanking = false
            showSettings = false
            navigator.isPlayingTimeAttack = false
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                navigator.isPlayingTimeAttack = true
            }
        }
        .onAppear(perform: presentTutorialIfNeeded)
    }

    private func menuButton(_ title: String,
                            prominent: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity)
        }
        .ffButtonStyle(prominent: prominent, tint: FFColor.green)
    }

    private func presentTutorialIfNeeded() {
        // スクリーンショット撮影中はチュートリアルを出さない（表示済みの記録も残さない）。
        guard !ScreenshotFixture.isActive, storage.object(forKey: "tutorial") == nil else { return }
        showTutorial = true
        storage.set(true, forKey: "tutorial")
    }
}
