//
//  SettingsView.swift
//  FFMultiply
//
//  設定画面。UI層(ツールバー/ボタン)は Liquid Glass、コンテンツ層は FF ブランド(settingGray)。
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var showTutorial = false

    private let storage = UserDefaults.standard

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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        storage.set(name, forKey: "playername")
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            name = storage.object(forKey: "playername") as? String ?? ""
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
