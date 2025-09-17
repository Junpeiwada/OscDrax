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

## 提供される主なクラスと機能

| クラス | 役割 | 主なメソッドやプロパティ |
| --- | --- | --- |
| `SynthUIAdapter` | UI 層と音声エンジンの橋渡し | `setupTrack(_:)`, `updateHarmonyFrequencies(...)`, `formantType`, ライフサイクルハンドラ各種 |
| `SynthEngineService` | `SynthEngineProtocol` 実装。トラック管理とハーモニー計算を担当 | `registerTrack(_:)`, `updateTrack(_:)`, `setTrackIsPlaying(_:isPlaying:)` |
| `SynthTrackParameters` | トラック状態を渡す DTO | `waveformType`, `frequency`, `volume`, `harmonyEnabled` など |
| `AudioEngine` (Platform) | `AVAudioEngine` を直接操作するローレベル層 | `createOscillator(with:)`, `updateFrequency`, `updateWaveform` |
| `FormantFilter` (Platform) | AVAudioUnitEQ を用いたフォルマントフィルタ | `setFormantType(_:)`, `smoothTransition(to:)` |

## SwiftUI での利用サンプル

```swift
import SwiftUI

struct SynthExampleView: View {
    @StateObject private var track1 = Track(id: 1)
    @StateObject private var track2 = Track(id: 2)
    @StateObject private var synth = SynthUIAdapter.shared

    var body: some View {
        VStack {
            Slider(value: Binding(get: {
                Double(track1.frequency)
            }, set: { newValue in
                track1.frequency = Float(newValue)
            }), in: 110...880)
            .padding()

            Button(track1.isPlaying ? "Stop" : "Play") {
                track1.isPlaying.toggle()
            }
        }
        .onAppear {
            synth.configureAudioSession()
            synth.setupTrack(track1)
            synth.setupTrack(track2)
            synth.startEngineIfNeeded()
        }
        .onDisappear {
            synth.deactivateAudioSession()
        }
    }
}
```

上記では `Track` モデルの `@Published` プロパティを更新すると、自動的に `SynthUIAdapter` 経由で `SynthEngineService` に伝搬されます。

### ハーモニー更新の例

```swift
func updateHarmony() {
    let tracks = [track1, track2, track3, track4]
    if let lead = tracks.first(where: { $0.isHarmonyLead }) {
        synth.updateHarmonyFrequencies(
            leadTrack: lead,
            allTracks: tracks,
            chordType: .major
        )
    }
}
```

### アプリライフサイクルへの組み込み例 (SwiftUI SceneDelegate 相当)

```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
    synth.handleWillResignActive()
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
    synth.handleDidEnterBackground()
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    synth.handleWillEnterForeground()
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
    synth.handleDidBecomeActive()
}
```

これらを組み合わせることで、他プロジェクトでも OscDrax のシンセサイザ機能を簡単に再利用できます。
