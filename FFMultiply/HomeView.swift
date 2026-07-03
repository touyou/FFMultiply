//
//  HomeView.swift
//  FFMultiply
//
//  ホーム画面。key_visual と 4 つのアクション、最下部にバナー広告。
//  初回起動時はチュートリアルを表示する。
//

import SwiftUI

struct HomeView: View {
    @State private var showGame = false
    @State private var showLocalScore = false
    @State private var showOnlineRanking = false
    @State private var showSettings = false
    @State private var showTutorial = false

    private let storage = UserDefaults.standard

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Image("key_visual")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .padding(.horizontal, 40)
                    .padding(.top, 32)

                Spacer(minLength: 24)

                VStack(spacing: 14) {
                    menuButton("time attack", prominent: true) { showGame = true }
                    menuButton("local score", prominent: false) { showLocalScore = true }
                    menuButton("online ranking", prominent: false) { showOnlineRanking = true }
                    menuButton("settings", prominent: false) { showSettings = true }
                }
                .controlSize(.large)
                .padding(.horizontal, 40)

                Spacer(minLength: 24)

                BannerAdView()
                    .frame(width: 320, height: BannerAdView.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FFColor.white.ignoresSafeArea())
        }
        .fullScreenCover(isPresented: $showGame) {
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
        guard storage.object(forKey: "tutorial") == nil else { return }
        showTutorial = true
        storage.set(true, forKey: "tutorial")
    }
}
