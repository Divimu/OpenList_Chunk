<div align="center">
  <img src="https://raw.githubusercontent.com/OpenListTeam/Logo/main/logo.svg" width="128" height="128" alt="logo" />

  <h1>OpenList_Chunk</h1>

  <p><em>CDN アップロードサイズ制限を回避する OpenList の強化フォーク</em></p>

  <a href="https://github.com/zmabin/OpenList_Chunk/actions?query=workflow%3ABuild"><img src="https://img.shields.io/github/actions/workflow/status/zmabin/OpenList_Chunk/build.yml?branch=main" alt="Build status" /></a>
  <a href="https://github.com/zmabin/OpenList_Chunk/releases"><img src="https://img.shields.io/github/v/release/zmabin/OpenList_Chunk" alt="latest version" /></a>
  <a href="https://github.com/zmabin/OpenList_Chunk/blob/main/LICENSE"><img src="https://img.shields.io/github/license/zmabin/OpenList_Chunk" alt="License" /></a>
</div>

---

[English](./README_en.md) | [中文](./README.md) | **日本語** | [Nederlands](./README_nl.md)

---

## 概要

**OpenList_Chunk** は [OpenList](https://github.com/OpenListTeam/OpenList) の強化フォークです。元のデータ構造を変更せずに、アップロードロジックを再構築し、CDN（Cloudflare など）のアップロードサイズ制限（無料版で 100MB）を回避します。

---

## 機能

- **Form 分割アップロード**: セッションベースのマルチパート分割 + `io.MultiReader` によるストリーミングマージ
- **Stream 分割アップロード**: Content-Range ヘッダーを使用したゼロコピーパイプ分割（ディスク使用量ゼロ）
- **CRC32 検証**: 各チャンクの整合性をチェック
- **自動クリーンアップ**: 期限切れチャンクディレクトリを定期的に削除

詳細については [中国語の README](./README.md) または [英語の README](./README_en.md) をご覧ください。

---

## ルート

| ルート | メソッド | 機能 |
|--------|----------|------|
| `/api/fs/put/chunk/init` | POST | 分割セッションを初期化 |
| `/api/fs/put/chunk` | PUT | チャンクをアップロード |
| `/api/fs/put/chunk/merge` | POST | チャンクをマージしてアップロード |

---

## 謝辞

- [LusiyAvA/openlist-chunk](https://github.com/LusiyAvA/openlist-chunk) — 分割アップロード機能の核心的なアイデアと実装参考
- [OpenListTeam/OpenList](https://github.com/OpenListTeam/OpenList) — 安定した基盤フレームワーク

---

## サポート

このプロジェクトが役に立ったら、⭐ Star をお願いします！

バグやご提案がありましたら、[Issue](https://github.com/zmabin/OpenList_Chunk/issues) をご投稿ください。
