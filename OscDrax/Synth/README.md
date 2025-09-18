# Synth モジュール — ライブラリ利用ガイド

OscDrax の音声合成機能を他プロジェクトで再利用できるよう切り出したモジュールです。UI からは `SynthUIAdapter` のみを扱えばよく、内部では `AVAudioEngine` を用いた DSP を隠蔽します。

## 要件

- 対応 OS: iOS 15+ / macOS 12+
- 開発言語: Swift 5.8+
- 依存: AVFoundation（`AVAudioEngine`）

## 導入（Installation）

- 最短手順: `OscDrax/Synth/` フォルダをそのままプロジェクトに追加
  - Xcode でグループとして追加し「Copy items if needed」を有効化
  - 併せて `OscDrax/Models/Track.swift` を利用するか、後述の「カスタムモデル」節の通りに独自モデルで置き換え
- Swift Package 化は未対応（Tips は末尾参照）

## クイックスタート

```swift
import SwiftUI

struct SynthExampleView: View {
    @StateObject private var track1 = Track(id: 1)
    @StateObject private var track2 = Track(id: 2)
    @StateObject private var synth = SynthUIAdapter.shared

    var body: some View {
        VStack {
            Slider(value: Binding(get: { Double(track1.frequency) }, set: { track1.frequency = Float($0) }), in: 110...880)
            Button(track1.isPlaying ? "Stop" : "Play") { track1.isPlaying.toggle() }
        }
        .onAppear {
            synth.configureAudioSession()
            synth.setupTrack(track1)
            synth.setupTrack(track2)
            synth.startEngineIfNeeded()
        }
        .onDisappear { synth.deactivateAudioSession() }
    }
}
```

ポイント:
- `setupTrack(_:)` を呼ぶと、`Track` の `@Published` 変更を自動でエンジンに反映
- アプリのライフサイクル通知は `SynthUIAdapter` のハンドラに委譲

## ライフサイクル連携

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

## 公開 API（概要）

- `SynthUIAdapter`（UI 層の窓口）
  - セッション: `configureAudioSession()`, `deactivateAudioSession()`, `startEngineIfNeeded()`
  - トラック接続: `setupTrack(_:)`
  - ハーモニー: `updateHarmonyFrequencies(leadTrack:allTracks:chordType:)`
  - 状態: `@Published var formantType: FormantType`, `@Published var masterVolume: Float`, `silentModePolicy: SynthSilentModePolicy`
- `SynthEngineProtocol`（エンジンの契約）と実装 `SynthEngineService`
  - トラック: `registerTrack(_:)`, `updateTrack(_:)`, `setTrackIsPlaying(_:isPlaying:)`
  - ハーモニー: `updateHarmonyFrequencies(...) -> [SynthTrackFrequencyUpdate]`
  - フォルマント: `var formantType`, `var formantTypePublisher`
  - マスターボリューム: `var masterVolume`, `var masterVolumePublisher`（0.0〜1.0、既定 1.0）
- `SynthTrackParameters`（DTO）
  - `waveformType`, `waveformData`, `frequency`, `volume`, `isPlaying`, `portamentoTime`, `vibratoEnabled`, `harmonyEnabled`, `scaleType`
- 音楽理論ユーティリティ
  - `WaveformType`, `ChordType`, `ScaleType`, `HarmonyInterval`, `FormantType`

関連ファイル:
- Core: `Core/SynthUIAdapter.swift`, `Core/SynthEngineService.swift`, `Core/SynthTypes.swift`, `Core/MusicTheory.swift`, `Core/FormantType.swift`
- Platform: `Platform/AudioEngine.swift`, `Platform/FormantFilter.swift`

## 設計と依存関係

```
UI (SwiftUI / UIKit)
   │
   └─ SynthUIAdapter  ──▶  SynthEngineService  ──▶  AudioEngine (AVAudioEngine)
                           ▲                    └─ FormantFilter (AVAudioUnitEQ)
                           │
                           └─ DTO / Enum (WaveformType, FormantType, etc.)
```

UI 層は `SynthUIAdapter` にのみ依存します。`SynthEngineService` 以下はプラットフォーム層を差し替えることで移植可能です。

## ハーモニー（コード生成）

```swift
let tracks = [track1, track2, track3, track4]
if let lead = tracks.first(where: { $0.isHarmonyLead }) {
    synth.updateHarmonyFrequencies(
        leadTrack: lead,
        allTracks: tracks,
        chordType: .major
    )
}
```

- 使用する音程は `ChordType` により決定（例: `.major`, `.minor`, `.seventh`, `.power`, `.detune`）
- 結果は `SynthTrackFrequencyUpdate` で返り、サンプル実装では `Track.apply(update:)` で UI 状態へ反映

## フォルマントとサイレントスイッチ

- フォルマント切替: `synth.formantType` を更新（内部で EQ をスムーズに補間）
- サイレントスイッチ方針: `synth.silentModePolicy = .ignoresMuteSwitch` or `.respectsMuteSwitch`

## スレッド・パフォーマンス

- UI からの変更は Combine で監視し、必要な差分のみ `AudioEngine` へ適用
- オーディオ処理は `AVAudioSourceNode` のレンダーブロック内で実行
- 多数トラックを同時発音する場合は CPU 使用率に注意（ミキサのマスター音量はクリッピング抑制のため低めに設定）

## 注意点・既知の制約

- iOS/macOS 専用（`AVAudioEngine` 依存）
- SwiftPM パッケージ未対応（フォルダコピーで動作）
- `Track` はサンプル実装。独自モデルを使う場合は `SynthTrackParameters` を構築して `SynthEngineService` に渡す

## 独自モデル（Track なし）での利用例

```swift
final class MyTrack: ObservableObject, Identifiable {
    let id: Int
    @Published var waveformType: WaveformType = .sine
    @Published var waveformData: [Float] = WaveformType.sine.defaultSamples()
    @Published var frequency: Float = 440
    @Published var volume: Float = 0.5
    @Published var isPlaying: Bool = false
    @Published var portamentoTime: Float = 0
    @Published var harmonyEnabled: Bool = false
    @Published var assignedInterval: HarmonyInterval?
    @Published var isHarmonyLead: Bool = false
    @Published var vibratoEnabled: Bool = false
    @Published var scaleType: ScaleType = .none

    init(id: Int) { self.id = id }

    var synthParameters: SynthTrackParameters {
        SynthTrackParameters(
            id: id,
            waveformType: waveformType,
            waveformData: waveformData,
            frequency: frequency,
            volume: volume,
            isPlaying: isPlaying,
            portamentoTime: portamentoTime,
            harmonyEnabled: harmonyEnabled,
            assignedInterval: assignedInterval,
            isHarmonyLead: isHarmonyLead,
            vibratoEnabled: vibratoEnabled,
            scaleType: scaleType
        )
    }
}

// 既存 Track を使わない場合は、エンジンに直接登録・更新します
import Combine

let engine = SynthEngineService.shared
let t = MyTrack(id: 1)
var bag = Set<AnyCancellable>()

engine.configureAudioSession()
engine.startEngineIfNeeded()
engine.registerTrack(t.synthParameters)

// 変更監視（必要なものだけ購読）
t.$isPlaying.removeDuplicates().sink { engine.setTrackIsPlaying(t.id, isPlaying: $0) }.store(in: &bag)
Publishers.MergeMany(
    t.$frequency.map { _ in () },
    t.$volume.map { _ in () },
    t.$waveformData.map { _ in () },
    t.$portamentoTime.map { _ in () },
    t.$vibratoEnabled.map { _ in () },
    t.$harmonyEnabled.map { _ in () },
    t.$isHarmonyLead.map { _ in () },
    t.$scaleType.map { _ in () }
)
.debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
.sink { engine.updateTrack(t.synthParameters) }
.store(in: &bag)
```

備考: `SynthUIAdapter` はサンプルの `Track` に結びついた監視を行います。独自モデルを使う場合は、`SynthUIAdapter` と同等の監視（Combine サブスクリプション）をアプリ側で実装するか、`SynthUIAdapter` を拡張してください。

## 参照（主要型）

- 波形: `WaveformType`（`sine/triangle/square/sawtooth/custom`、`defaultSamples()`）
- スケール: `ScaleType`（`quantizeFrequency(_:)` で周波数を丸め）
- フォルマント: `FormantType`（`formantFrequencies/Q/gain/outputGain`）
- DTO: `SynthTrackParameters`、ハーモニー結果: `SynthTrackFrequencyUpdate`

## Swift Package 化のヒント（任意）

- ローカルパッケージとして `Synth/` を独立させ、`Sources/Synth/...` に移動し `Package.swift` を作成
- product は `.library(name: "Synth", targets: ["Synth"])`
- target 依存は `AVFoundation` のみ
