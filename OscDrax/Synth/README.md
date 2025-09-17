# Synth モジュールの概要と利用方法

このフォルダには OscDrax の音声合成機能を他プロジェクトでも再利用できるように切り出したモジュールが含まれます。構成は次の 2 階層です。

- `Core/` — プラットフォーム非依存の API・データモデル・サービス層
  - `FormantType.swift`: フォルマント設定を表す列挙体
  - `MusicTheory.swift`: 波形種別やスケールなど音楽理論関連の列挙体／ヘルパー
  - `SynthTypes.swift`: トラックパラメータ DTO、インターフェイスなど
  - `SynthEngineService.swift`: 音声エンジンの公開サービス実装（`SynthEngineProtocol` 準拠）
  - `SynthUIAdapter.swift`: SwiftUI など UI 層から SynthEngine を操作するためのアダプタ
- `Platform/` — iOS/macOS 依存のローレベル実装
  - `AudioEngine.swift`: `AVAudioEngine` を用いた DSP 実装
  - `FormantFilter.swift`: AVAudioUnitEQ を用いたフォルマントフィルタ

## 他プロジェクトへの組み込み手順

1. `Synth/` フォルダ全体をコピーし、利用先プロジェクトに追加する
   - Xcode の場合はグループとして追加し、「Copy items if needed」を有効にします。
2. UI 層で `SynthUIAdapter.shared` を `@StateObject` 等で保持し、以下のメソッドを呼び出して初期化します。
   ```swift
   let synth = SynthUIAdapter.shared
   synth.configureAudioSession()
   synth.setupTrack(track1)
   synth.setupTrack(track2)
   synth.startEngineIfNeeded()
   ```
3. `Track` モデル（または同等の ObservableObject）を用意し、`track.synthParameters` を通して音声エンジンへ更新を伝搬します。
4. アプリライフサイクル（バックグラウンド遷移等）で `SynthUIAdapter` のハンドラを呼び出してください。
   ```swift
   synth.handleWillResignActive()
   synth.handleDidEnterBackground()
   synth.handleWillEnterForeground()
   synth.handleDidBecomeActive()
   ```
5. ハーモニー更新が必要な場合は `synth.updateHarmonyFrequencies(leadTrack:allTracks:chordType:)` を使用します。

## 構造と依存関係

```
UI (SwiftUI / UIKit)
   │
   └─ SynthUIAdapter  ──▶  SynthEngineService  ──▶  AudioEngine (AVAudioEngine)
                           ▲                    └─ FormantFilter (AVAudioUnitEQ)
                           │
                           └─ DTO / Enum (WaveformType, FormantType, etc.)
```

UI 層は `SynthUIAdapter` にのみ依存します。`SynthEngineService` 以下の実装は Platform 層を差し替えることで他プラットフォームにも対応可能です。

## 注意点

- このモジュールは `AVAudioEngine` を利用するため、iOS/macOS でのみ動作します。
- SwiftPM 化はしていませんが、フォルダ構成を保ったままコピーすれば動作します。
- ハーモニー計算やトラックの状態同期は `Track` モデル側で `SynthTrackParameters` を生成する実装が必要です。
