# OscDrax - iOS オシレーターアプリ仕様書

## 概要
- **アプリ名**: OscDrax
- **プラットフォーム**: iOS / iPadOS
- **開発フレームワーク**: SwiftUI + Combine + AVAudioEngine
- **対応OS**: iOS 17.6 以上（iPhone / iPad 両対応）
- **画面方向**: iPhone は縦固定（Portrait / PortraitUpsideDown）、iPad は全方向対応
- **UI特徴**: Liquidglass スタイルのカード UI とヘルプオーバーレイ

## 主要機能

### 1. トラック管理
- 4 つの独立したトラック（ID: 1〜4）
- 各トラックは再生状態・波形・パラメータを個別保持
- タブバーに MiniWaveformView を表示し、音量バー・割り当てインターバル・再生インジケーターを提供
- トラックを切り替えても音声は継続再生

### 2. 波形作成・編集
- 画面上部に波形描画ビュー（512 サンプル）
- ドラッグジェスチャーで手描き波形をリアルタイム編集
- プリセット波形: Sin / Triangle / Square / Saw（ポップオーバーで選択）
- プリセット選択時は波形タイプを更新し、描画中でも音声を途切れさせない
- `Clear` ボタンでカスタム波形をフラットラインにリセット

### 3. 周波数・スケール制御
- 20Hz〜20,000Hz の対数スライダー（ドラッグ開始位置に依存せず反応）
- スケール選択: None / Major / Major Pentatonic / Minor Pentatonic / Japanese
- スケール有効時は周波数を即時クオンタイズ
- ポルタメントスライダー（0〜1,000ms）で滑らかな遷移時間を設定

### 4. ハーモニー機能
- トラックごとに Harmony ON/OFF を切り替え可能
- グローバルなコードタイプ: Major / Minor / 7th / m7 / Power / Detune
- Detune は ±10cent, +20cent の微分周波数を自動割り当て
- 最新で周波数を変更したトラックを自動的にハーモニーリードに設定し、他トラックへインターバルを割り当て
- 割り当て結果（Root, 3rd, 5th など）はトラックタブに表示・保存される

### 5. ビブラート
- 各トラックにビブラート ON/OFF トグル
- 周波数安定後 500ms で 5Hz / 1% 深度のモジュレーションを開始
- ポルタメント遷移中は自動的にビブラートを抑制

### 6. 音量・再生制御
- ボリュームスライダー（0〜100%）は即時に反映
- Play/Stop ボタンで各トラックを独立制御（同時発音可能）
- 50ms のフェードイン／フェードアウトでクリックノイズを抑制

### 7. フォルマントフィルタ
- Formant セレクタ: None / A / I / U / E / O
- AVAudioUnitEQ を用いておおよそ 3 帯域のフォルマント特性を適用
- 変更時は 0.1s のスムーズな遷移を実施し、出力ゲインを -3dB 補正

### 8. ヘルプオーバーレイ
- 各セクションに `info` ボタンを配置し、操作説明を日本語/英語で表示
- オーバーレイはタップまたは OK ボタンで閉じる

### 9. データ永続化
- アプリがバックグラウンド/終了する際に `Documents/oscdrax_state.json` へ保存
- 起動時に 4 トラック分のパラメータを復元（再生状態は起動時に OFF に戻す）

## UI レイアウト（概略）
```
+-----------------------------+
|          Waveform           |
|        (描画エリア)         |
+-----------------------------+
| [Waveform ▼]         [Clear]|
| Frequency  [====◎====] 440Hz |
| Scale: [Major Pentatonic ▼] |
| Harmony  ☐   Vibrato  ☐     |
| Chord: Major Minor 7th ...  |
| Volume    [===◎=====]  60%  |
| Portamento[==◎====] 120ms   |
| Formant: None  A  I  U  E  O|
|           [ ▶ Play ]        |
| [Tab1] [Tab2] [Tab3] [Tab4] |
+-----------------------------+
```

## 技術仕様

### オーディオパイプライン
- `AVAudioEngine` + `AVAudioSourceNode`（各トラック）
- `AVAudioMixerNode` → `FormantFilter (AVAudioUnitEQ)` → `mainMixerNode`
- サンプリングレート: 44,100Hz
- サンプル形式: 32-bit Float, モノラル
- 推奨 IO バッファ: 512 フレーム（約 11.6ms）
- マスター出力ボリューム: 0.3（多トラック時のクリッピングを防止）

### スレッドセーフティ & 更新制御
- 各 `OscillatorNode` で NSLock によるパラメータ保護
- 波形データはダブルバッファリングでリアルタイム書き換え
- Combine によるデバウンス: 周波数/音量 5ms、波形 10ms、ポルタメント 10ms
- 再生/停止は即時反映（デバウンスなし）

### 音声合成エンジン構成
```swift
final class SynthUIAdapter: ObservableObject
  - UI 層から共有インスタンスを利用
  - Track の Combine 購読をセットアップ
  - formantType の双方向バインディングを提供

final class SynthEngineService: SynthEngineProtocol
  - AudioEngine とトラックスナップショットを管理
  - ハーモニー計算 / フォルマント遷移 / サイレントモードポリシーを担当

final class AudioEngine: ObservableObject
  - AVAudioEngine 構成、FormantFilter の差し込み
  - OscillatorNode の生成・接続・更新

final class OscillatorNode
  - AVAudioSourceNode で波形テーブル再生
  - 線形補間、ポルタメント、ビブラート、フェード制御を実装
```

### 波形処理
- 波形テーブルサイズ: 512 サンプル
- 線形補間で滑らかな値を取得
- 手描き波形はタッチ位置をテーブルインデックスへ正規化
- プリセット波形は `WaveformType.defaultSamples` で生成（Sin / Triangle / Square / Saw / Custom）

### ミキシングとダイナミクス
- 各トラックで `tanh(sample * 0.7)` によるソフトクリッピングを実施
- `AVAudioMixerNode` が全トラックを加算ミックスし、出力を FormantFilter へ送る
- マスターボリューム係数: 0.0〜1.0（既定 1.0、将来の別アプリで UI 露出予定）

### データ保存フォーマット
- JSON（Codable）でトラック配列を保存
- 保存例：
  ```json
  {
    "tracks": [
      {
        "id": 1,
        "waveformType": "sine",
        "waveformData": [0.0, 0.5, 1.0, ...],
        "frequency": 440.0,
        "volume": 0.5,
        "isPlaying": false,
        "portamentoTime": 120.0,
        "harmonyEnabled": true,
        "assignedInterval": "Root",
        "isHarmonyLead": true,
        "vibratoEnabled": false,
        "scaleType": "Major"
      }
    ]
  }
  ```
- 互換性保持のため `isHarmonyMaster` キーを `legacyHarmonyFlag` としてデコード

### オーディオセッション
- `SynthSilentModePolicy` でミュートスイッチの扱いを切り替え（既定は `.ignoresMuteSwitch`）
- `AVAudioSessionCategoryPlayback` を基本とし、必要に応じて `.ambient` を使用
- サンプリングレート / IO バッファは `AudioEngine` の推奨値を設定

### 対応デバイス
- iPhone（縦画面想定）
- iPad（マルチウィンドウ・回転対応）

## 初期値
- 波形: Sine
- 周波数: 440Hz
- ボリューム: 50%
- ポルタメント: 0ms
- ハーモニー: 有効
- 調性: None（自由）、コードタイプ: Major
- ビブラート: OFF
- フォルマント: None
- 再生状態: 停止

## 実装済み機能
1. ✅ 手描き波形 & プリセット波形（Sin/Triangle/Square/Saw）
2. ✅ 4 トラック独立制御（MiniWaveform 表示付き）
3. ✅ ポルタメント（0〜1,000ms）
4. ✅ スケールクオンタイズ（Major / Pentatonic / Japanese）
5. ✅ ハーモニー自動生成（Detune 含む）
6. ✅ ビブラート（遅延付き自動開始）
7. ✅ フォルマントフィルタ（母音シミュレーション）
8. ✅ JSON 永続化（再生状態は復元時に OFF）
9. ✅ LaunchScreen（SplashImage）
