#!/usr/bin/env node
// 旧ランキング `scores/<端末 ID>` を、key を SHA-256 にした `scores_legacy/<hash>` へ写す。
// 端末 ID（iOS の identifierForVendor / Android の広告 ID）をほかの利用者に配らないため。
// salt はアプリ側（iOS RankingService.legacyKeySalt / Android RankingService.LEGACY_KEY_SALT）と同じにする。
//
// 使い方（Mac で firebase CLI にログイン済みのとき）:
//   firebase database:get /scores --export > /tmp/scores.json
//   node scripts/migrate-legacy-scores.mjs /tmp/scores.json > /tmp/scores_legacy.json
//   firebase database:update /scores_legacy /tmp/scores_legacy.json
// 何度流しても同じ結果になる（同じ key に同じ値を書くだけ）。`scores` 側は消さない。
// 書き出しから書き込みまでの間にアプリが消した行は戻るが、アプリは登録のたびに自分の旧行を消し直す。
// 書き出しは毎回 update の直前に取り直すこと。

import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

export const LEGACY_KEY_SALT = "ffmultiplier-ranking-legacy:";

export function hashedLegacyKey(deviceID) {
  return createHash("sha256").update(LEGACY_KEY_SALT + deviceID, "utf8").digest("hex");
}

/** `scores` の書き出し（--export 付き）から、`scores_legacy` に書く内容を作る。 */
export function migrate(scores) {
  const out = {};
  for (const [deviceID, record] of Object.entries(scores ?? {})) {
    if (typeof record !== "object" || record === null) continue;
    if (typeof record.score !== "number") continue;
    const entry = { name: typeof record.name === "string" ? record.name : "", score: record.score };
    // 並び順はアプリが点数で付け直すが、旧データと同じく priority = -score も残す。
    entry[".priority"] = record[".priority"] ?? -record.score;
    out[hashedLegacyKey(deviceID)] = entry;
  }
  return out;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const path = process.argv[2];
  if (!path) {
    console.error("usage: node scripts/migrate-legacy-scores.mjs <scores.json>");
    process.exit(1);
  }
  const scores = JSON.parse(readFileSync(path, "utf8"));
  process.stdout.write(JSON.stringify(migrate(scores), null, 2) + "\n");
}
