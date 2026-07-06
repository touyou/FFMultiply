//
//  GameView.swift
//  FFMultiply
//
//  タイムアタック本体。上半分に表示部（タイマー・問題・入力・操作）、
//  下半分に 4×4 の 16進キーパッドを配置する。ダーク基調。
//

import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var vm = GameViewModel()
    @State private var didStart = false
    @State private var didFinish = false
    @State private var showResult = false
    @State private var isHighScore = false
    @State private var showNamePrompt = false
    @State private var nameInput = ""

    private let storage = UserDefaults.standard

    var body: some View {
        VStack(spacing: 0) {
            displaySection
            keypadSection
        }
        .background(FFColor.blackBackground.ignoresSafeArea())
        .statusBarHidden()
        .toast($vm.toast)
        .task {
            // 広告表示などで一時的に view が disappear→reappear すると .task が
            // 再実行される。その際にゲームを初期化し直して score が 0 に戻るのを防ぐ。
            guard !didStart else { return }
            didStart = true
            vm.start()
            while !vm.isFinished {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                vm.tick()
            }
            finishGame()
        }
        .overlay {
            if showResult {
                ZStack {
                    FFColor.blackReversible.opacity(0.3).ignoresSafeArea()
                    ResultView(score: vm.score, isHighScore: isHighScore) {
                        dismiss()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showResult)
        .alert("register name", isPresented: $showNamePrompt) {
            TextField("user name", text: $nameInput)
            Button("OK") {
                guard !nameInput.isEmpty else { return }
                storage.set(nameInput, forKey: "playername")
                RankingService.shared.register(name: nameInput, score: vm.score)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("please set your username")
        }
    }

    // MARK: - 表示部

    private var displaySection: some View {
        VStack(spacing: 16) {
            // 上バー: 左ダミー / タイマー / 閉じる
            HStack {
                Color.clear.frame(width: 50, height: 1)
                Spacer()
                Text(vm.timeText)
                    .font(.dseg7(size: 17))
                    .foregroundStyle(FFColor.green)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("✕")
                        .font(.system(size: 30))
                        .foregroundStyle(FFColor.white)
                }
                .frame(width: 50)
            }
            .padding(.horizontal)

            Spacer()

            // 問題: 左オペランド × 右オペランド
            HStack(spacing: 12) {
                operandLabel(vm.leftText)
                Text("×")
                    .font(.system(size: 41))
                    .foregroundStyle(FFColor.white)
                operandLabel(vm.rightText)
            }

            // 入力表示
            Text(vm.displayInput)
                .font(.dseg7(size: 40))
                .foregroundStyle(FFColor.white)

            Spacer()

            // 操作バー: DELETE(破壊的=赤) / score / DONE(確定=緑) を役割で明確に差別化
            HStack {
                Button {
                    vm.delete()
                } label: {
                    actionLabel("DELETE", systemImage: "delete.left.fill", background: FFColor.red)
                }
                Spacer(minLength: 8)
                Text(vm.scoreText)
                    .font(.dseg7(size: 20))
                    .foregroundStyle(FFColor.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(FFColor.lightGrayBackground)
                    .clipShape(.rect(cornerRadius: 8))
                Spacer(minLength: 8)
                Button {
                    vm.done()
                } label: {
                    actionLabel("DONE", systemImage: "checkmark", background: FFColor.green)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 役割の異なるアクション（DELETE/DONE）用の塗りカプセルラベル。
    private func actionLabel(_ title: String, systemImage: String, background: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.futuraBold(size: 16))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(background, in: .capsule)
    }

    private func operandLabel(_ text: String) -> some View {
        Text(text)
            .font(.dseg7(size: 48))
            .foregroundStyle(FFColor.blackReversible)
            .frame(minWidth: 64, minHeight: 72)
            .padding(8)
            .background(FFColor.whiteBackground)
            .clipShape(.rect(cornerRadius: 8))
    }

    // MARK: - キーパッド

    private var keypadSection: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { col in
                        let value = row * 4 + col
                        keypadButton(value)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FFColor.blackBackground)
    }

    private func keypadButton(_ value: Int) -> some View {
        let fnum = FNum(rawValue: value) ?? .zero
        return Button {
            vm.tapNumber(fnum)
        } label: {
            Text(convertFNum(toStr: fnum))
                .font(.dseg7(size: 36))
                .foregroundStyle(FFColor.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
        }
    }

    // MARK: - 終了処理

    private func finishGame() {
        guard !didFinish else { return }
        didFinish = true

        let store = ScoreStore(context: modelContext)
        store.add(score: vm.score)

        // ハイスコア判定（保存後の最高スコアが今回スコア以下なら更新）。
        let best = store.highScore()?.score ?? vm.score
        isHighScore = best <= vm.score

        if isHighScore {
            if let name = storage.object(forKey: "playername") as? String, !name.isEmpty {
                RankingService.shared.register(name: name, score: vm.score)
            } else {
                nameInput = ""
                showNamePrompt = true
            }
        }

        AdManager.shared.presentInterstitial()
        showResult = true
    }
}
