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
        gameLayout
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

    // MARK: - レイアウト

    /// 表示部（上）とキーパッド（下）の配置。
    /// iOS 27.1 以降は `ArrangementView` に任せ、iPhone Duo の半開きなどハードウェアの状態に
    /// 合わせて表示部と操作部（キーパッド）をシステムが分割配置できるようにする。
    @ViewBuilder
    private var gameLayout: some View {
        if #available(iOS 27.1, *) {
            ArrangementView {
                displaySection
            } secondary: {
                keypadSection
            }
            // 分割方向はシステムに任せる。上下に限定すると、iPhone Duo の内側画面を
            // 横長にしたとき上下に収まらずキーパッドが非表示になるため。
            .arrangementViewStyle(.split)
        } else {
            VStack(spacing: 0) {
                displaySection
                keypadSection
            }
        }
    }

    // MARK: - 表示部

    private var displaySection: some View {
        VStack(spacing: 16) {
            // 上バー: 閉じる（左・安全領域内）/ タイマー（横幅いっぱいを基準に中央）。
            // 右上はシステムの予約領域になり得るため閉じるボタンは左に置き、
            // タイマーは下のキーパッド等と中心線を揃える。
            ZStack {
                Text(vm.timeText)
                    .font(.dseg7(size: 17))
                    .foregroundStyle(FFColor.green)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .horizontal)
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        // ツールバーのボタンと同様の円形ガラスにして押せる場所を明確にする。
                        // iPhone Duo では上端の安全領域が 0 になり画面最上部に来るため、
                        // ガラス込みで 44pt 程度のタップ領域を確保する。
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(FFColor.white)
                            .frame(width: 30, height: 30)
                    }
                    .ffGlassCircleButtonStyle()
                    .accessibilityLabel("Close")
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)

            Spacer()

            // 問題: 左オペランド × 右オペランド
            HStack(spacing: 12) {
                operandLabel(vm.leftText)
                Text("×")
                    .font(.system(size: 41))
                    .foregroundStyle(FFColor.white)
                operandLabel(vm.rightText)
            }
            // キーパッドと中心線を揃えるため、問題・入力表示も横幅いっぱいを基準に中央寄せする。
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .horizontal)

            // 入力表示
            Text(vm.displayInput)
                .font(.dseg7(size: 40))
                .foregroundStyle(FFColor.white)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .horizontal)

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
            // 操作バーもキーパッドと同じ横幅に揃える（右上のタイマー・閉じるボタンは安全領域内に残す）。
            .ignoresSafeArea(edges: .horizontal)
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
        // 電卓と同様にキーパッドは横幅いっぱいに広げる。iPhone Duo などで
        // 左右に縦型バーの安全領域があっても、キーをそこまで均等に配置する。
        .ignoresSafeArea(edges: .horizontal)
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
