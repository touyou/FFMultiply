# FFMultiply モダン化 — 引き継ぎ資料（自己完結版）

> このドキュメントは、Xcode連携セッションが `.xcworkspace` 削除で失われても作業を継続できるように、
> 全ての決定事項・調査結果・手順・設計仕様を1ファイルにまとめたもの。
> 新しいセッションはまずこれを読めば Phase 0 以降を単独で完遂できる。
> 元の計画ファイル: `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/plans/witty-conjuring-lark.md`（消える可能性あり／本ドキュメントが正）

## 0. 現在の状態（最終更新: 2026-07-04）

- 作業ブランチ: **`modernize/swiftui-depods`**（master から作成済み）。
- 計画はユーザー承認済み。

### 進捗（2026-07-04 セッション: SwiftUI全面書き換え実施）

**AIが完了した分（§5の新規ファイルを `XcodeWrite` で作成、旧ファイルを `XcodeRM` で削除）:**
- 新規作成: `App/FFMultiplyApp.swift`, `App/AppDelegate.swift`, `DesignSystem/{FFColor,FFFont,GlassStyles}.swift`,
  `Model/{ScoreEntry(SwiftData),LegacyRealmScore(移行用Realm Object,クラス名は旧スキーマ互換で `Score`)}.swift`,
  `Services/{ScoreStore,RealmMigration,RankingService,AdManager,BannerAdView}.swift`,
  `Views/{HomeView,GameView,GameViewModel,LocalScoreView,OnlineRankingView,OnlineRankingViewModel,SettingsView,ResultView,TutorialView,ToastModifier}.swift`。
- 上書き: `Views/ResultView.swift` と `Views/TutorialView.swift`（旧UIKit版→新SwiftUI版）、`Support File/Info.plist`。
- 削除: 旧 `Support File/AppDelegate.swift`, `ViewController/`5ファイル, `Model/ScoreModel.swift`,
  `CircularRevealAnimator/`2ファイル, `Utility/ToastSwift.swift`, `Views/{ResultView,TutorialView}.xib`,
  `Storyboard/{Main,LaunchScreen}.storyboard`。
- **残置（意図通り）:** `Utility/FFUtility.swift`（純ロジック。§5では Model/ 配下想定だが移動せず現位置のまま流用）, `Assets/`, `GoogleService-Info.plist`, `FFMultiply.entitlements`。
- Info.plist: `UIMainStoryboardFile`/`UILaunchStoryboardName` を撤去し、`UILaunchScreen` 辞書へ。
  `GADApplicationIdentifier`, `UIAppFonts`(DSEG7), `SKAdNetworkItems`(暫定で `cstr6suwn9.skadnetwork` のみ), `NSUserTrackingUsageDescription` を追加。`UIRequiredDeviceCapabilities(armv7)` は削除。

**✅ ビルド成功（2026-07-04）**: realm-swift を 20.0.0 以降へ更新後、Liquid Glass を iOS 26 で `#available` ガード（`GlassStyles.swift` に集約、iOS18は material/tint フォールバック）してビルド成功。エラー0。

**✅ シミュレータ起動+UI目視検証（2026-07-04, iPhone 17 Pro Max iOS26.5/27）**: 起動成功・クラッシュなし。DSEG7フォントは正しくロード（Game画面がセブンセグ表示）。Realm重複クラス警告はユーザーが `Realm` product をターゲットから外して解消済み。

**デザイン方針（ユーザー確定）: 「UI層(コントロール)は Liquid Glass / コンテンツ層は FF ブランドカラーでしっかり」**。
- UI層: ボタン=`.buttonStyle(.ffGlass)`（内部で iOS26 `glassEffect`、iOS18は material/tint フォールバック）、sheetは `NavigationStack`+ツールバー（Cancel/Save 等が iOS26 で自動ガラス化）、ポップアップ(Result/Tutorial/Toast)は `ffGlassCard`。
- コンテンツ層: 各画面の背景 FFカラー（Home=白, Game=黒, LocalScore=茶, Ranking=緑, Settings=グレー）+ Futura/DSEG7。

**UI調整（2026-07-04 実施・目視OK）:**
- Home: key_visual を `maxHeight:200` に制約、間延び解消、広告 320×50。→ 自然なサイズに。
- Settings: `NavigationStack`+ツールバー(Cancel/Save)化、USER NAME欄+HELP(ガラス)、広告320×50。
- Game: 入力表示を DSEG7 17→40pt に拡大（他は据え置き。ユーザー評価「割と良い」）。
- Result: 固定300×300をやめ Liquid Glass カード化。得点を緑DSEG7 72ptで大きく表示（**旧「得点未反映」は固定枠+ダーク配色衝突が原因、解消**）。High Scoreはcrownバッジ。SHARE/EXITはガラスピル。
- 広告: `largeAnchoredAdaptiveBanner`(高さ50-150で大きすぎ)→ **標準バナー `AdSizeBanner`(320×50)** に変更。

**フロー注意（既存仕様）**: ハイスコア時、名前未登録だと「register name」アラートが **Result表示の前** に出る。将来UX改善の余地あり（Result内やSettings誘導に寄せる等）。

**UIブラッシュアップ第2弾（2026-07-04）**: コントラスト比と Liquid Glass 部の「太さ」を底上げ。（後述の第3弾でボタン方針を再転換）

**ボタン方針の再転換＝標準ボタン採用（2026-07-04, ユーザー判断）**: カスタム角丸ガラスボタン `FFGlassButtonStyle`/`.ffGlass` は「くすむ・背景に馴染んで見にくい」ため**廃止**。SwiftUI 標準の `.bordered` / `.borderedProminent` に全面移行（iOS26 では自動 Liquid Glass 化、iOS18 では通常ボタン、両対応でコンパイル可）。`ffGlassCard`（Result/Tutorial/Toast のカード）は残す。
- 背景色ごとに tint を最適化: 白地(Home)=`time attack` prominent緑 / 他 bordered `blackReversible`(濃色テキスト)。茶地(LocalScore)=EXIT bordered白 / DELETE **prominent赤(role:.destructive)**。緑地(Ranking)=EXIT/SHARE bordered白 / REGISTER prominent `blackReversible`(黒塗り)。
- Result: SHARE prominent緑 / EXIT bordered。得点=黒地チップ+緑DSEG7、HighScore=赤カプセル白文字（下地非依存で可読）。
- Game DELETE/DONE は塗りカプセル（赤/緑+アイコン）で役割明確化（据え置き）。Settings は NavigationStack+ツールバー、USER NAME欄を大きめBOX化、HELP=bordered。
- **シミュレータ目視で全画面のコントラスト確認済み。Online Ranking は Firebase 実データがロードされ priority 降順並びも実動作確認。**
- 既知の軽微点: 色地上の白 bordered(EXIT/SHARE)は輪郭が控えめ（可読性はOK）。以降のUI微調整はユーザー主導。

**ボタン方針の最終形＝標準 Liquid Glass ボタン + ツールバー化（2026-07-04, ユーザー指摘反映）**:
- `GlassStyles.swift` に **`ffButtonStyle(prominent:tint:)`** ヘルパーを追加。`#available(iOS 26)` を1箇所に閉じ込め、iOS26=**本物の `.glass` / `.glassProminent`**、iOS18=`.bordered`/`.borderedProminent` にフォールバック。`#available` は実行時OS判定なので Deployment Target 18 のままでも iOS26 実機/シミュレータでは本物のガラスになる（ユーザーは「iOS26以上でも可」だが現状18維持のまま両対応）。将来 iOS18 を切るなら本ヘルパーの分岐を消して直接 `.glass` にできる。
- 適用: Home 4メニュー（time attack=prominent緑 / 他=glass、全て full-width で幅統一）、Result(SHARE=prominent緑 / EXIT=glass, equal width)、Settings HELP、Tutorial EXIT。
- **スコア系画面をツールバー化**（ユーザー要望「EXITはツールバーのクローズでも」）: LocalScore / OnlineRanking を `NavigationStack`+`.toolbar` 化。principal=Futuraタイトル、`.cancellationAction`=✕(xmark)クローズ、trailing=アクション(LocalScore:trash / Ranking:share)。ボトムの EXIT/SHARE/DELETE を廃し、Ranking は「REGISTER MY SCORE」の full-width ガラスボタン1つに集約。→ 幅の不揃い解消。
- シミュレータ(iOS26)で目視確認済み: Home 4ボタン等幅の本物ガラス、スコア系はツールバー(✕/タイトル/アクション)がガラス円形ボタンで表示、Firebase実データ表示。

**残タスク / フォローアップ:**
1. **【要対応・pbxproj領域】Realm 重複クラス警告**: コンソールに `Class RLM... is implemented in both Realm.framework and RealmSwift.framework ... may cause mysterious crashes` が多数出る。原因は**ターゲットに `Realm` と `RealmSwift` の両方の product をリンクしている**こと（RealmSwift が Realm を内包するので二重）。→ Xcode で Target > General > Frameworks, Libraries, and Embedded Content から **`Realm` を削除（`RealmSwift` は残す）**。これで警告消滅。非致命的だが「エラーに見える」出力の正体。
2. パッケージ: 全てリンク済み・ビルド/起動OK。**任意: FirebaseCrashlytics product を外す**（未使用）。**推奨: `OTHER_LDFLAGS` に `-ObjC`**（AdMob要件、未設定でもビルド/起動は通った）。
3. ~~警告: banner の非推奨API~~ → **解消済み**（`BannerAdView.swift` を `largeAnchoredAdaptiveBanner(width:)` に置換、Swift名は SDK ヘッダ NS_SWIFT_NAME で確認）。自作コードのビルド警告は 0 件。
4. **目視検証（Phase 7）まだ**: 初回チュートリアル→1プレイ→Result→ローカルスコア反映→設定で名前保存→オンラインランキング表示。
4. **DSEG7 フォント名**: `.custom("DSEG7ClassicMini-Bold", ...)`。実PostScript名が違うと標準フォントにフォールバックするので表示で要確認（`mdls` では PostScript名取得不可だった）。
5. Liquid Glass の見た目は iOS 26 シミュレータでのみ確認可能（iOS18ではフォールバック表示）。
6. 旧Realmデータ移行の実データ確認（§8）。
3. **DSEG7 のフォント名要確認**: `.custom("DSEG7ClassicMini-Bold", size:)` を使用。実PostScript名が異なる場合は `FFFont.swift` の名前を修正（`Font.familyNames`/フォント情報で確認）。
4. **SKAdNetworkItems** は暫定1件のみ。配信品質のためGoogle公式の全リストへ拡充推奨。
5. Firebase priority 並び（`queryOrderedByPriority` / `setValue(_,andPriority:)`）の挙動は実機/実DBで要確認（§4末尾・§9）。
6. 潜在的な Swift 6 並行性の詰め（AdManager/RankingService の @MainActor 境界、Firebaseコールバックの Sendable 等）はビルドエラーを見て対応。

**設計メモ（実装済みの挙動）:**
- 遷移: Home=`NavigationStack`、ゲーム=`.fullScreenCover`、Local/Online/Settings=`.sheet`、Result/Tutorialポップアップ=`overlay`(半透明+ガラスカード)。
- ゲームタイマー: `GameView` の `.task` 内 `while !isFinished { Task.sleep(1s); vm.tick() }`。終了時に SwiftData保存→ハイスコア判定→(高得点かつ名前未設定なら)名前入力alert→Firebase登録→インタースティシャル→Resultオーバーレイ。
- 名前入力は SwiftUI `.alert` + `TextField`。Share は `ShareLink`。空表示は `ContentUnavailableView`。
- **重要な制約**: Xcode が開いている間、`project.pbxproj` を直接編集すると Xcode がクラッシュするため **私（AI）は pbxproj を一切編集しない**。
  - ファイルの作成/上書き → MCP `XcodeWrite`（Xcode経由でtargetに自動追加され安全）
  - ファイル削除/移動 → MCP `XcodeRM` / `XcodeMV`
  - **パッケージ管理・CocoaPods除去・ビルド設定変更（pbxproj編集が必要なもの）→ ユーザーがXcode/ターミナルで実施**（AIは手順を案内）
- ユーザー要望により、**Phase 0（`.xcworkspace`削除を含む依存整理）は、この引き継ぎを残してから実施**する。

## 1. ゴールと確定方針

2016年製の16進掛け算ゲーム（App Store id `1151801381`, bundle `com.dev.touyou.FFMultiply`, 表示名 `FFMultiplier`）。
UIKit + Storyboard/XIB → **全面SwiftUI化 + 脱CocoaPods + 依存最新化**。元デザイン踏襲＋適所にLiquid Glass。

**確定方針（ユーザー確認済み）:**
1. **AdMob維持** — SPM導入 + モダンAPI + SwiftUIラッパー
2. **SwiftDataへ移行** — 既存Realmデータの一度きり移行処理付き（移行のため realm-swift を1リリースだけ温存）
3. **オンラインランキング維持** — Firebase を 11.x 系へ更新

**デプロイ設定（現状維持）:** iOS 18.0 / Swift 6.0 / DevelopmentTeam `B4S4333JDW` / Portrait固定。

## 2. 現状の潜在バグ（モダン化で必ず直す）

1. **広告コードがビルド不能の疑い**: 旧コードは `GADInterstitial` / `kGADAdSizeSmartBannerLandscape` / `GADMobileAds.configure(withApplicationID:)` 等、Google-Mobile-Ads-SDK v12 で削除済みAPIを使用。
2. **DSEG7フォント未登録**: `Info.plist` に `UIAppFonts` が無く、セブンセグ風フォント `DSEG7ClassicMini-Bold.ttf` が実際にはロードされず標準フォントにフォールバック。→ `UIAppFonts` に追加して本来の見た目に。

## 3. Phase 0 手順（依存整理・ユーザー主体）

### 3-1. CocoaPods 除去（Xcodeを終了してから、ターミナルで）
```
cd /Users/touyou/Developer/Private/FFMultiply
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod deintegrate   # Ruby4.0で失敗する場合は下の手動除去へ
rm -rf Pods Podfile Podfile.lock FFMultiply.xcworkspace
```
> `pod deintegrate` が Unicode正規化エラー（Ruby 4.0非互換）で失敗する場合の**手動除去**（`.xcodeproj`を閉じた状態で pbxproj を編集）:
> - `[CP] Check Pods Manifest.lock` / `[CP] Embed Pods Frameworks` / `[CP] Copy Pods Resources` の3つの ShellScript build phase を削除
> - Frameworks build phase から `Pods_FFMultiply.framework` を削除、対応する PBXBuildFile / PBXFileReference / Frameworksグループ・Podsグループを削除
> - Debug/Release の target 設定にある `baseConfigurationReference`（Pods-FFMultiply.*.xcconfig）を削除
> - PBXBuildFile / PBXFileReference から `Pods-FFMultiply.debug/release.xcconfig` を削除

その後 **`FFMultiply.xcodeproj` を開く**（`.xcworkspace` はもう無い）。

### 3-2. SPM パッケージ更新（Xcode > File > Add Package Dependencies / Package Dependencies タブ）
| パッケージ | URL | バージョン | 使用product |
|---|---|---|---|
| Firebase | `https://github.com/firebase/firebase-ios-sdk` | Up to Next Major **11.0.0** | **FirebaseDatabase** のみ（FirebaseCrashlytics は削除） |
| Realm | `https://github.com/realm/realm-swift` | **最新メジャー**（下記注意） | **RealmSwift**（移行用に一時温存） |

> ⚠️ **realm-swift のバージョン注意（2026-07-04 ビルドで判明）**: 「Up to Next Major 10.0.0」だと古い 10.x が解決され、同梱 realm-core(C++) が `std::is_pod` を特殊化するため、現行 Xcode/C++ 標準ライブラリで `'is_pod' cannot be specialized` ビルドエラーになる。**Dependency Rule を実際の最新メジャー（例: 20.0.0 以降）に設定**し、File > Packages > Update to Latest Package Versions で更新すること。移行専用の一時依存なので最新で問題ない。
| Google Mobile Ads | `https://github.com/googleads/swift-package-manager-google-mobile-ads.git` | Up to Next Major **12.x** | **GoogleMobileAds** |

- 旧 `realm-cocoa`(5.4.2) と旧 firebase branch `6.32-spm-beta` は削除して上記に置換。
- AdMob追加時、依存の GoogleUserMessagingPlatform は自動解決される。

### 3-3. ビルド設定
- `OTHER_LDFLAGS` に `-ObjC` を追加（AdMob要件）。

### 3-4. AIが安全にできる Phase 0 分（ファイル削除）
以下の旧ファイルは `XcodeRM` で削除（Phase 6と統合してもよい）:
`FFMultiply/CircularRevealAnimator/`（2ファイル）, `FFMultiply/Model/ScoreModel.swift`,
`FFMultiply/Storyboard/`（Main/LaunchScreen）, `FFMultiply/ViewController/`（5ファイル）,
`FFMultiply/Views/ResultView.swift`+`.xib`, `FFMultiply/Views/TutorialView.swift`+`.xib`,
`FFMultiply/Utility/ToastSwift.swift`, `FFMultiply/Support File/AppDelegate.swift`（新App構成に置換）。
**残すもの:** `FFMultiply/Utility/FFUtility.swift`（純ロジック、再利用）, `Assets/`（xcassets+ttf）,
`Support File/Info.plist`+`GoogleService-Info.plist`, `FFMultiply.entitlements`。

## 4. 調査結果（AdMob v12 / Firebase 11）

### AdMob（Google Mobile Ads SDK v12+, Swiftで `GAD` プレフィックス撤廃）
- 初期化: `MobileAds.shared.start(completionHandler:)`（旧 `GADMobileAds.sharedInstance().start`）
- バナー: `BannerView`（旧 `GADBannerView`）。`.adUnitID` / `.rootViewController` / `.load(Request())` / `.adSize`
  - アダプティブサイズ: `currentOrientationAnchoredAdaptiveBanner(width:)`（SmartBannerは廃止）
- インタースティシャル: `InterstitialAd.load(with: adUnitID, request: Request())`（async か completion）→ `.present(from: viewController)`
- リクエスト: `Request()`（旧 `GADRequest`）。名前衝突時は `GoogleMobileAds.Request` と名前空間指定。
- import は `import GoogleMobileAds`。
- **Info.plist 必須キー:**
  - `GADApplicationIdentifier` = `ca-app-pub-2853999389157478~4868410869`
  - `SKAdNetworkItems`（Googleの `cstr6suwn9.skadnetwork` 他）
  - ATT用に `NSUserTrackingUsageDescription`（任意だが推奨）
- SwiftUIでは `UIViewRepresentable` で `BannerView` をラップ、インタースティシャルは `@Observable` の AdManager で管理。

### 広告ユニットID（現行踏襲）
- App ID: `ca-app-pub-2853999389157478~4868410869`
- バナー: `ca-app-pub-2853999389157478/6345144062`
- インタースティシャル: `ca-app-pub-2853999389157478/3692728869`

### Firebase 11（Realtime Database）
- `import FirebaseCore` + `import FirebaseDatabase`。初期化 `FirebaseApp.configure()`。
- `Database.database().reference()` は健在。`.child("scores").child(device_id).setValue([...], andPriority: -score)`、
  `.queryOrderedByPriority().observe(.value)` も概ね維持。**要動作確認**（priorityベースの並びが意図通りか。ダメなら score キーでの並び替えに変更）。

## 5. 目標アーキテクチャ（新規ファイル群 / `XcodeWrite`で作成）

ディスク配置は `FFMultiply/` 直下に整理（Xcodeのグループは自動）。
```
App/
  FFMultiplyApp.swift        @main App + @UIApplicationDelegateAdaptor + .modelContainer(SwiftData) + 起動時にRealm移行
  AppDelegate.swift          FirebaseApp.configure() と MobileAds.shared.start() のみ
DesignSystem/
  FFColor.swift              Asset "FFxxx" を Color として型安全に公開
  FFFont.swift               Futura / DSEG7 の Font ヘルパー（.dseg7(size:) 等）
  GlassStyles.swift          Liquid Glass 共通 modifier / ボタンスタイル
Model/
  FFUtility.swift            【既存を移動 or そのまま】純ロジック（FNum, FFProblem, makeProblem, fTimes 等）
  ScoreEntry.swift           SwiftData @Model（date: Date, score: Int）
  LegacyRealmScore.swift     移行専用 Realm Object（旧 Score 相当: date: NSDate, score: Int）
Services/
  ScoreStore.swift           SwiftData 読み書き（ハイスコア/一覧/全削除）@MainActor
  RealmMigration.swift       初回起動時に旧Realm→SwiftDataへ一度きり移行（UserDefaultsフラグ管理）
  RankingService.swift       Firebase Realtime DB を async/await でラップ
  AdManager.swift            @Observable。MobileAds起動・InterstitialAd load/present
  BannerAdView.swift         UIViewRepresentable で BannerView
Views/
  HomeView.swift             key_visual + 4ボタン(time attack/local score/online ranking/settings) + バナー
  GameView.swift             ダーク基調。上部:タイマー/問題/入力/result、下部:4x4キーパッド(0-9,A-F)
  GameViewModel.swift        @Observable。出題/入力/採点/コンボ/タイマー/リザルト
  LocalScoreView.swift       SwiftData一覧。空表示は ContentUnavailableView
  OnlineRankingView.swift    Top50/Nearby セグメント、SHARE/REGISTER、Your Rank表示
  OnlineRankingViewModel.swift
  SettingsView.swift         ユーザー名TextField、HELP(チュートリアル)、CANCEL/SAVE、バナー
  ResultView.swift           リザルトカード（Result / HighScore / スコア / SHARE / EXIT）
  TutorialView.swift         TabView(.page) で tutorial1..6、EXIT
  ToastModifier.swift        accepted/failed トースト（旧ToastSwift代替）
```

- 遷移: ホームは `NavigationStack`、ゲームは `.fullScreenCover`、スコア/設定/ランキングは `.sheet` か push。ポップアップ(Result/Tutorial)は overlay か sheet。
- 状態管理: `@Observable`（Combine不使用、async/await優先）。ゲームタイマーは `.task`+`Task.sleep`（旧 `Timer` 代替）。

## 6. アプリ仕様（ロジック踏襲のための詳細）

### ゲームルール（旧 GameViewController より）
- 制限時間 **60秒**。`makeProblem(1000)` で問題生成、popLast で1問ずつ出題。
- 入力は最大2文字。16進 0-9,A-F。`inputNumberLabel` は入力中の値、空なら `"--"`。
- 採点: `nowProblem.2 == nowValue` で正誤判定。トーストに `"accepted"`/`"failed"`（extraShort）。
- スコア: `pointsAccepted=10, pointsFailed=-5, pointsCombo=5, maxComboBonus=15`。
  - 正解: `score += 10 + min(5*(combo/5), 15)`、`combo += 1`
  - 不正解: `score += -5`、`combo = 0`
- 終了時: Realm(→SwiftData)へ `date, score` を保存。ハイスコア更新時は Firebase 更新 + 名前未設定なら入力アラート。インタースティシャル提示。

### Firebase（オンラインランキング）
- `device_id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString`
- 書込: `ref.child("scores").child(device_id).setValue(["name": name, "score": score], andPriority: -score)`
- 読込: `ref.child("scores").queryOrderedByPriority().observe(.value)` → 各値 `{name, score}` を score降順にランク付け。
- Top50 と「自分の周辺(Nearby)」の2モード。REGISTER=自分の最高スコア登録、SHARE=結果シェア。

### UserDefaults キー
- `"tutorial"`（初回起動でチュートリアル表示済みか。存在すれば表示しない）
- `"playername"`（ユーザー名）

### 共有（Share）
- 文言例: `"I got \(score) points! Let's play FFMultiplier with me! #FFMultiplier"` / ランキング: `"My rank is \(rank)! ..."`
- URL: `https://itunes.apple.com/us/app/ffmultiplier/id1151801381?l=ja&ls=1&mt=8`
- `UIActivityViewController` 相当（SwiftUIは `ShareLink`）。`.print` は除外していた。

## 7. デザイン仕様（元デザイン踏襲）

### フォント
- **DSEG7ClassicMini-Bold**（セブンセグ）: タイマー / 問題の左右オペランド(48pt) / 入力表示 / result / キーパッドの数字。※要 `UIAppFonts` 登録。
- **Futura-Bold**: 各画面タイトル（Result/Local Score/Online Ranking等）17pt。
- **Futura-Medium**: 各種ボタン・ラベル 14〜17pt。
- 記号 `×`(41pt system), `✕`(30pt system) 等。

### FFカラー（Asset `FFColors/*.colorset`, sRGB。Light / Dark）
| 名前 | Light | Dark |
|---|---|---|
| FFBlackBackground | #111111 | #1A1A1A |
| FFBlackReversible | #000000 | #FFFFFF |
| FFBrown | #B97C50 | #875B3A |
| FFDarkGray | #676767 | #999999 |
| FFGray | #BBBBBB | #EDEDED |
| FFGreen | #85BF5D | #A8F276 |
| FFGreenBackground | #85BF5D | #618C45 |
| FFLightGrayBackground | #333333 | #000000 |
| FFRed | #B33737 | #E64749 |
| FFSettingGray | #EFEFF3 | #BEBEC2 |
| FFWhite | #F9F8F5 | #C7C6C4 |
| FFWhiteBackground | #FFFFFF | #000000 |

### 画面別レイアウト要約
- **Home**: 背景 FFWhite。上部に `key_visual` 画像（aspect fit）。下に4ボタン縦並び（time attack / local score / online ranking / settings, Futura-Medium 17, 文字色 #555555, 各高さ40）。最下部にバナー広告。
- **Game**: 背景 FFBlackBackground（#111）。上半分=表示部（上バー: 左ダミー50 / 中央タイマー DSEG7 17pt FFGreen / 右✕。中段: 左オペランド DSEG7 48 × 右オペランド DSEG7 48（背景 FFWhiteBackground）。入力表示 DSEG7 17 "--"。操作バー: DELETE(FFRed, Futura-Bold17) / result(中央, FFLightGrayBackground背景, DSEG7 17, FFWhite) / DONE(FFGreen, Futura-Bold17)）。下半分=4×4キーパッド（行順: 0 1 2 3 / 4 5 6 7 / 8 9 A B / C D E F。背景 FFBlackBackground、文字 FFGray、DSEG7。tag 0-15）。
- **LocalScore**: 背景 FFBrown。タイトル "Local Score"(Futura-Bold17, 白)。テーブル(背景白, cell "n. XX points / date: ...")。下部 EXIT / DELETE(Futura-Medium14, FFDarkGray)。空表示は ContentUnavailableView。
- **OnlineRanking**: 背景 FFGreenBackground。タイトル "Online Ranking"(白)。SegmentedControl "Top50 | Nearby"(白tint)。テーブル(白)。"Your Rank: n"(Futura-Medium14, #555, 白背景)。下部 EXIT / SHARE / REGISTER。
- **Settings**: 背景 FFSettingGray(#EFEFF3)。タイトル "Settings"。ユーザー名TextField(角丸, 背景白, placeholder "user name", Futura-Medium17)。中央 HELP(チュートリアル起動)。下部 CANCEL / SAVE。最下部バナー。
- **Result(ポップアップ 300x300)**: 背景白。上バー "Result"(FFBlackReversible背景, 白文字, Futura-Bold17)。"🎉High Score🎉"(ハイスコア時のみ表示)。中央にスコア(DSEG7 大)。SHARE / EXIT(Futura-Medium17, FFGray)。
- **Tutorial(ポップアップ 400x483)**: 背景白。上に app icon `ffmultiicon`。中央に tutorial画像(tutorial1..6)。下部 👈 / EXIT / 👉。
- **Launch**: 背景 FFWhite。中央 `key_visual`。下部にコピーライト。→ SwiftUI化に伴い `Info.plist` の `UILaunchScreen` 辞書での起動画面に置換（Storyboard廃止）。旧: `Copyrights © 2016- touyou. All Rights Reserved.`(Futura-Medium11, #AAAAAA)。

### Liquid Glass 適用方針（iOS 26+ API）
- API: `.glassEffect(_:in:)`（例 `.glassEffect(in: .rect(cornerRadius: 16))`）, `.buttonStyle(.glass)` / `.glassProminent`, `GlassEffectContainer`, `Glass.regular.tint(_:).interactive()`。
- 適用: Result/Tutorialポップアップカード・Toast → `.glassEffect(in:.rect(...))`。Home/Settings/Score各アクションボタン → `.buttonStyle(.glass)`（色味は元踏襲を tint で）。ゲームのキーパッドは電卓感優先でGlassは控えめ。

## 8. 検証（Phase 7）
- `BuildProject` でコンパイル確認、`XcodeRefreshCodeIssuesInFile` で逐次診断。
- `RunProject` / シミュレータで: 初回チュートリアル → ゲーム1プレイ → リザルト → ローカルスコア反映 → 設定で名前保存 → オンラインランキング表示 を目視。
- 旧Realmデータ移行: 旧Realmファイルを用意して初回起動での取り込み確認（無理ならコードレビューで担保）。

## 9. リスク
- Realm移行のため realm-swift を1リリース温存。最新 realm-swift が旧(core6世代)ファイルを開けるか要確認。
- Firebase 6→11 の priority系API挙動要確認。
- AdMob SmartBanner廃止でバナー寸法が変わる → 元の見た目に寄せる調整。
- pbxproj編集はAI不可。パッケージ/Pods/ビルド設定変更はユーザー実施。ファイル追加/削除は `XcodeWrite`/`XcodeRM`。

## 10. 次セッションの進め方
1. 本ドキュメントを読む。ブランチ `modernize/swiftui-depods` にいることを確認（`git branch --show-current`）。
2. Phase 0（§3）— ユーザーと分担。Pods除去とパッケージ更新はユーザー、旧ファイル削除はAI。
3. Phase 1〜6 — §5 のファイルを `XcodeWrite` で実装、§6-7 の仕様に忠実に。
4. Phase 7 — §8 の検証。
5. コミットは Phase 単位で小さく。commit/push はユーザー指示があるまで（またはブランチ運用ルールに従い）行う。
