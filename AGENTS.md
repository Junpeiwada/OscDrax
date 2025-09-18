# AGENTS 指示（会話言語の既定）

このリポジトリで行う会話・出力・提案は、特段の指定がない限り、常に日本語で行ってください。

## 目的
- 利用者が日本語で快適にやり取りできるようにするため。

## 指示
1. 既定の応答言語は日本語。
2. ユーザーが明示的に別言語（例: 英語）を要求した場合のみ、その言語に切り替える。
3. コード、コマンド、API 名、ファイルパスは原文（英語）表記のままでよい。
4. 回答は簡潔・実務的に。必要に応じて箇条書き・短い見出しを用いる。
5. 変更を伴う作業では、実行前に短いプレアンブル（何をするか 1～2 文）を示し、主要な進捗を簡潔に共有する。

## スコープ
- 本ファイルが置かれたディレクトリ配下の全ての作業に適用されます。
- より深い階層に別の AGENTS.md がある場合、そちらの指示が優先されます。

---

# このプロジェクトで作業する際のガイド

## リポジトリ構成（要点）
- アプリ本体: `OscDrax/`（SwiftUI）
- シンセモジュール: `OscDrax/Synth/`
  - Core（プラットフォーム非依存）: `Core/`
  - Platform（iOS/macOS 依存）: `Platform/`
- 画像等アセット: `OscDrax/Assets.xcassets/`
- 永続化: `OscDrax/Persistence/`
- ドキュメント: `docs/`, `AppStore_Description*.md`, `OscDrax/Synth/README.md`
- Lint 設定: `.swiftlint.yml`
- 開発補助: `Makefile`, `Scripts/`

## ビルド・実行
- Xcode: `OscDrax.xcodeproj` を開く → Scheme `OscDrax`
- Makefile（macOS ターミナル）:
  - `make build`（macOS 用ビルド）
  - `make clean`
  - `make test`（現状テスト最小）
- 音は `AVAudioEngine` 出力。低レイテンシ確認や実機のオーディオ挙動確認はデバイスで行うと良い。

## Lint/フォーマット
- 実行: `make lint`, `make lint-fix`, `make format`
- 方針は `.swiftlint.yml` に従う（主なもの）
  - 行長: 120（警告）/200（エラー）
  - 関数長: 40（警告）/100（エラー）
  - 強制アンラップ/try/cast: warning 扱い
  - プリント禁止: `print()` は警告（ロガー使用）

## コードスタイル・設計の原則
- 変更は最小限・局所的に。副作用の広いリネーム/再配置は避ける。
- 公開 API に触れる変更は、`OscDrax/Synth/README.md` を必ず更新。
- 命名は Swift の一般慣習に従い、略語を避ける。アクセス制御は最小権限（`private`/`internal`）。
- Combine/SwiftUI の購読は `AnyCancellable` を適切に保持し、循環参照を避ける（`[weak self]`）。
- ログは `OSLog` 経由。`print` は使用しない。

## オーディオ/DSP の注意（重要）
- `Platform/AudioEngine.swift` のレンダーブロックはリアルタイムスレッド。以下を避ける：
  - メモリアロケーション/解放、ファイル I/O、フォーマット変換、大量のロック/待ち
  - `DispatchQueue` を使った同期
- 既存実装は波形テーブルのダブルバッファと `NSLock` を最小限に使用。追加処理も同レベルの軽さを維持。
- 波形テーブルサイズは `SynthConstants.defaultWaveformSampleCount`（既定 512）。変更時は補間・CPU 負荷を考慮。
- マスターミキサ音量はクリッピング抑制のため低め（`mixer.outputVolume`）。複数トラック時の音量設計に注意。

## Synth モジュール拡張の方針
- プラットフォーム非依存の型/ロジックは `Synth/Core/` に配置。
- `AVAudioEngine` など依存がある実装は `Synth/Platform/` に配置。
- UI からの操作は `SynthUIAdapter` を介す。新規パラメータは
  1) `SynthTrackParameters` に追加 →
  2) `SynthEngineService.updateTrack` に差分適用処理 →
  3) `AudioEngine` に反映 →
  4) 必要なら `Track` の `@Published` を増設 → `SynthUIAdapter` で購読
- ハーモニー関連は `MusicTheory.swift` と `SynthEngineService` の `updateHarmonyFrequencies` を拡張。

## 永続化と互換性
- `OscDrax/Persistence/PersistenceManager.swift` は `Track` 配列を JSON で保存。
- `Track` の `Codable` 互換性を壊さないこと。
  - フィールド追加は `decodeIfPresent` + 既定値を用いる。
  - 既存キーの名称変更は `CodingKeys` にレガシーキーを残す（本プロジェクトに例あり: `legacyHarmonyFlag`）。

## ドキュメント運用
- 公開 API 変更: `OscDrax/Synth/README.md` を更新。
- 動作仕様/設計: `docs/spec.md`, 実装メモ: `docs/impl.md` を参照・更新。
- スクリーンショット等は `docs/` へ。

## 依存と権限
- 依存: `AVFoundation`（マイクは未使用）。
- オーディオセッション: `playback` または `ambient` を状況に応じて使用（サイレントスイッチ方針は `SynthSilentModePolicy`）。

## 変更の粒度と PR
- 1 PR = 1 目的。影響範囲を小さく分割。
- 不具合の根治を優先。無関係なリファクタは別 PR。
- 大きな変更の前に仕様・設計を短く合意（Issue/メモで可）。

## 注意事項（この環境向け）
- 著作権ヘッダは追加しない。
- 大きなバイナリやアセットの差し替えは事前相談。
- 実装と同時に簡潔な説明/使用例を残すと、後続作業がスムーズです。
