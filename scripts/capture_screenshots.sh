#!/bin/bash
#
# App Store 提出用のスクリーンショットを端末・言語ごとに撮る。
#
#   ./scripts/capture_screenshots.sh                # 既定の端末（iphone duo-closed duo-open）すべて
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
#
# iPhone Duo は閉じた状態（外側の画面、縦 1398x2034）と開いた状態（内側の画面、横 2853x2007）を
# 撮り分ける。開閉はシミュレータのコマンドからは切り替えられず、DeviceHub でデバイスの下にある
# ボタンを押すしかない。なので撮る前に今の状態を確かめ、合っていなければ止める:
#
#   duo-closed  閉じた Duo で撮る（起動し直した直後は閉じている）
#   duo-open    DeviceHub で開いてから撮る
#
# 開いた状態ではテストが内側の画面を撮る（`SCREENSHOT_DUO_OPEN`）。内側のフレームバッファは
# 縦長のままなので、ここで時計回りに 90° 回して 2853x2007 に揃える。

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
DUO_OPEN_SIZE="2853x2007"
# 閉じているときの内側の画面（まっ黒）の PNG はこれより小さい。
DUO_INNER_BLANK_MAX_BYTES=1000000

# platform | destination
PLATFORMS=(
  "iphone|$IPHONE_DEST"
  "ipad|$IPAD_DEST"
  "duo-closed|$DUO_DEST"
  "duo-open|$DUO_DEST"
)
# 引数なしで撮る端末（iPad は上の理由で含めない）。
DEFAULT_PLATFORMS=(iphone duo-closed duo-open)

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

# 撮影先の UDID。id= ならそのまま、name= なら OS ごとの一覧から引く（Duo の開閉確認に使う）。
udid_for() {
  local destination=$1 udid name os
  udid=$(echo "$destination" | sed -nE 's/.*id=([0-9A-Fa-f-]{36}).*/\1/p')
  if [ -z "$udid" ]; then
    name=$(echo "$destination" | sed -nE 's/.*name=([^,]+).*/\1/p')
    os=$(echo "$destination" | sed -nE 's/.*OS=([0-9.]+).*/\1/p')
    udid=$(xcrun simctl list devices available \
      | awk -v os="-- iOS $os --" -v name="$name" '$0 == os {f=1; next} /^-- /{f=0} f && index($0, "    " name " (") == 1' \
      | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  fi
  echo "$udid"
}

pixel_size() {
  sips -g pixelWidth -g pixelHeight "$1" | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w"x"h}'
}

# Duo が期待した開閉状態か。内側の画面に何か映っているかで見分ける。
check_duo_state() {
  local platform=$1 destination=$2 udid shot bytes state
  udid=$(udid_for "$destination")
  if [ -z "$udid" ]; then
    echo "    FAILED — iPhone Duo のシミュレータが見つからない（$destination）"
    return 1
  fi
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b > /dev/null 2>&1 || true
  # 内側の画面は閉じている間まっ黒なので、PNG にすると 100KB ほどに縮む（中身があると数 MB になる）。
  # 既定の画面のサイズでは見分けられない（開いていても外側を横向きで返すことがある）。
  shot="$WORK/duo-inner.png"
  xcrun simctl io "$udid" screenshot --display=primary-1 "$shot" > /dev/null 2>&1
  bytes=$(stat -f%z "$shot" 2>/dev/null || echo 0)
  state=closed
  [ "$bytes" -gt "$DUO_INNER_BLANK_MAX_BYTES" ] && state=open
  case "$platform" in
    duo-open)
      if [ "$state" != open ]; then
        echo "    FAILED — Duo が閉じている。DeviceHub でデバイスの下のボタンを押して開いてから撮り直す"
        return 1
      fi ;;
    duo-closed)
      if [ "$state" != closed ]; then
        echo "    FAILED — Duo が開いている。DeviceHub で閉じるか、シミュレータを起動し直してから撮り直す"
        return 1
      fi ;;
  esac
  return 0
}

# PNG から向きの情報（eXIf と XMP）を取り除く。XCUIScreen の画像は「表示時に 90° 回す」の
# 印（orientation 6）を持っていて、画素を回したあとも残ると、ブラウザや App Store Connect が
# もう一度回してしまう。
strip_png_orientation() {
  python3 - "$1" <<'EXIF'
import struct, sys

path = sys.argv[1]
data = open(path, "rb").read()
out, i = [data[:8]], 8
while i < len(data):
    length, kind = struct.unpack(">I4s", data[i:i + 8])
    chunk = data[i:i + 12 + length]
    xmp = kind == b"iTXt" and data[i + 8:i + 8 + 17] == b"XML:com.adobe.xmp"
    if kind != b"eXIf" and not xmp:
        out.append(chunk)
    i += 12 + length
open(path, "wb").write(b"".join(out))
EXIF
}

# 開いた Duo の内側の画面は縦長のフレームバッファで返るので、横向きに回して 2853x2007 に揃える。
# XCUIScreen の画像は 1px 小さい（2006x2852）ので、最後に指定のサイズへ合わせる。
normalize_duo_open() {
  local dest=$1 png size w h
  for png in "$dest"/*.png; do
    size=$(pixel_size "$png")
    w=${size%x*}; h=${size#*x}
    if [ "$w" -lt "$h" ]; then
      sips -r 90 "$png" > /dev/null
    fi
    if [ "$(pixel_size "$png")" != "$DUO_OPEN_SIZE" ]; then
      sips -z "${DUO_OPEN_SIZE#*x}" "${DUO_OPEN_SIZE%x*}" "$png" > /dev/null
    fi
    strip_png_orientation "$png"
  done
  echo "    normalized to $DUO_OPEN_SIZE"
}

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

  case "$platform" in
    duo-*)
      if ! check_duo_state "$platform" "$destination"; then
        failed+=("$platform/$locale")
        return
      fi ;;
  esac

  prepare_simulator "$destination"

  # 開いた Duo のときだけ、テストに内側の画面を撮らせる（TEST_RUNNER_ を外した名前でテストに届く）。
  local duo_open=0
  if [ "$platform" = "duo-open" ]; then
    duo_open=1
  fi


  # -AppleLanguages の起動引数ではなく -testLanguage / -testRegion を使う。
  # こちらでないとアプリ内の `Locale.current` が変わらず、固定データの言語が切り替わらない。
  if ! TEST_RUNNER_SCREENSHOT_DUO_OPEN=$duo_open xcodebuild test \
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

  if [ "$platform" = "duo-open" ]; then
    normalize_duo_open "$dest"
  fi
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
