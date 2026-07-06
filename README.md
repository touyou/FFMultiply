# FFMultiply
某教授「九九じゃなくてFFを覚えましょう」

## ブランチ運用 / リリースフロー

- `main` … 開発の統合先となる通常のメインブランチ。
- `production` … リリース用ブランチ。**Xcode Cloud** がこのブランチを監視しており、push されるとビルド → App Store Connect への配信が自動実行される（fastlane / GitHub Actions は不使用）。

### リリース手順

1. 作業ブランチ（例: `release/x.y.z`）で修正とバージョン bump を行う。
   - `MARKETING_VERSION`（例: 2.0.1）と `CURRENT_PROJECT_VERSION`（例: 2.0.1.1）を Xcode の Build Settings で更新する（Debug / Release 両方）。
   - pbxproj は Xcode 起動中にツールで直接編集するとクラッシュするため、バージョン変更は Xcode 上で行う。
2. 作業ブランチを `main` にマージする。
3. `main` を `production` にマージ / push する → Xcode Cloud が自動でビルド & 配信。
