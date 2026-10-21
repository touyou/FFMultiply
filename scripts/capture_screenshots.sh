#!/bin/bash
#
# App Store 提出用のスクリーンショットを端末・言語ごとに撮る。
#
#   ./scripts/capture_screenshots.sh                # 既定の端末（iphone duo）すべて
#   ./scripts/capture_screenshots.sh iphone         # 指定した端末だけ
#   LOCALES="ja" ./scripts/capture_screenshots.sh   # 指定した言語だけ
#
# 出力先は Screenshots/<platform>/<locale>/NN-name.png（git では無視する）。
#
# UI テスト（FFMultiplyUITests/ScreenshotTests）がアプリを各画面まで進めて
# `XCUIScreen.main.screenshot()` を添付する。端末のフレームバッファそのものなので、
# App Store Connect が求めるピクセルサイズで撮れる。アプリは起動引数
# `-uitest-screenshot-fixture` で固定データ（ScreenshotFixture.swift）を使い、
# Firebase・広告・ATT/UMP のダイアログ・チュートリアルを出さない。
#
# 撮影先はシミュレータの名前と OS で指定する。ほかの作業と同じシミュレータを取り合わないよう、
# 環境変数で差し替えられる（`xcrun simctl clone` した専用の端末を指す想定）:
#
#   IPHONE_DEST="platform=iOS Simulator,id=<udid>" DUO_DEST="platform=iOS Simulator,id=<udid>" \
#     ./scripts/capture_screenshots.sh
#
# id= で指定した端末は撮影前に起動し、ステータスバーを 9:41・電波と電池が満タンの表示に固定する。

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
OUT="$ROOT/Screenshots"
WORK="${SCREENSHOT_WORK_DIR:-$ROOT/.screenshot-runs}"
LOCALES="${LOCALES:-en ja}"

SCHEME="FFMultiply"
TEST_ID="FFMultiplyUITests/ScreenshotTests"

IPHONE_DEST="${IPHONE_DEST:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=27.0}"
# iPad は既定では撮らない。FFMultiply は iPhone 専用（TARGETED_DEVICE_FAMILY = 1）で、
# App Store Connect も iPhone 専用アプリには iPad のスクリーンショットを求めない。
# iPad で動かしても iPhone アプリの互換モード表示になり、提出用の画にならない。
# 確認したいときだけ `./scripts/capture_screenshots.sh ipad` で明示的に指定する。
IPAD_DEST="${IPAD_DEST:-platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=27.0}"
# iPhone Duo は iOS 27.1 のシミュレータにしか無い。
DUO_DEST="${DUO_DEST:-platform=iOS Simulator,name=iPhone Duo,OS=27.1}"

# platform | destination
PLATFORMS=(
  "iphone|$IPHONE_DEST"
  "ipad|$IPAD_DEST"
  "duo|$DUO_DEST"
)
# 引数なしで撮る端末（iPad は上の理由で含めない）。
DEFAULT_PLATFORMS=(iphone duo)

requested=("$@")
[ ${#requested[@]} -eq 0 ] && requested=("${DEFAULT_PLATFORMS[@]}")
failed=()

wanted() {
  for name in "${requested[@]}"; do
    [ "$name" = "$1" ] && return 0
  done
  return 1
}

region_for() {
  case "$1" in
    ja) echo JP ;;
    *)  echo US ;;
  esac
}

mkdir -p "$WORK"

# id= で指定された端末を起動し、ステータスバーの表示を固定する（失敗しても撮影は続ける）。
prepare_simulator() {
  local destination=$1 udid
  udid=$(echo "$destination" | sed -nE 's/.*id=([0-9A-Fa-f-]{36}).*/\1/p')
  [ -z "$udid" ] && return 0
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b > /dev/null 2>&1 || true
  xcrun simctl status_bar "$udid" override \
    --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 \
    > /dev/null 2>&1 || true
}

capture() {
  local platform=$1 destination=$2 locale=$3
  local bundle="$WORK/$platform-$locale.xcresult"
  local log="$WORK/$platform-$locale.log"
  rm -rf "$bundle"

  prepare_simulator "$destination"

  # -AppleLanguages の起動引数ではなく -testLanguage / -testRegion を使う。
  # こちらでないとアプリ内の `Locale.current` が変わらず、固定データの言語が切り替わらない。
  if ! xcodebuild test \
    -project FFMultiply.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$destination" \
    -only-testing:"$TEST_ID" \
    -resultBundlePath "$bundle" \
    -testLanguage "$locale" \
    -testRegion "$(region_for "$locale")" \
    > "$log" 2>&1; then
    echo "    FAILED — see $log"
    failed+=("$platform/$locale")
    return
  fi

  local dest="$OUT/$platform/$locale"
  rm -rf "$dest" && mkdir -p "$dest"

  local staging="$WORK/$platform-$locale-attachments"
  rm -rf "$staging"
  xcrun xcresulttool export attachments --path "$bundle" --output-path "$staging" > /dev/null

  # 書き出されたファイル名は意味の無い名前なので、manifest.json でテストが付けた名前に戻す。
  python3 - "$staging" "$dest" <<'PY'
import json, pathlib, re, shutil, sys

staging, dest = (pathlib.Path(p) for p in sys.argv[1:3])
manifest = json.loads((staging / "manifest.json").read_text())

# XCTest は添付名の後ろに "_<index>_<uuid>" を付ける。
SUFFIX = re.compile(r"_\d+_[0-9A-Fa-f-]{36}$")

count = 0
for test in manifest:
    for attachment in test.get("attachments", []):
        exported = attachment.get("exportedFileName")
        name = attachment.get("suggestedHumanReadableName") or exported
        if not exported:
            continue
        stem = SUFFIX.sub("", pathlib.Path(name).stem)
        shutil.copyfile(staging / exported, dest / f"{stem}.png")
        count += 1

if count == 0:
    sys.exit("no attachments in the result bundle")
print(f"    {count} screenshot(s) -> {dest}")
PY
}

for entry in "${PLATFORMS[@]}"; do
  IFS='|' read -r platform destination <<< "$entry"
  wanted "$platform" || continue
  for locale in $LOCALES; do
    echo "==> $platform / $locale"
    capture "$platform" "$destination" "$locale"
  done
done

echo
echo "=== sizes ==="
if [ -d "$OUT" ]; then
  find "$OUT" -name "*.png" | sort | while read -r png; do
    size=$(sips -g pixelWidth -g pixelHeight "$png" | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w"x"h}')
    printf '%-40s %s\n' "${png#"$OUT"/}" "$size"
  done
fi

echo
if [ ${#failed[@]} -gt 0 ]; then
  echo "FAILED: ${failed[*]}"
  echo "Logs are in $WORK"
  exit 1
fi
echo "All captures succeeded. Open with: open $OUT"
