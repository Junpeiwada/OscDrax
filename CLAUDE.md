# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

OscDraxは音声波形を作成・操作するiOSオシレーターアプリケーションです。4つの独立したトラック、手描き波形作成、プリセット波形、リアルタイム周波数制御を備えています。

## コマンド

```bash
# 開発
make lint          # SwiftLintでコードスタイルをチェック
make lint-fix      # SwiftLintで自動修正
make format        # SwiftLintでコードフォーマット
make build         # Xcodeプロジェクトをビルド
make clean         # ビルド成果物をクリーン
make test          # ユニットテストを実行

# Xcodeで開く
open OscDrax.xcodeproj
```

## アーキテクチャ

### コアモデル
- **Track.swift**: SwiftUIバインディング用の`@Published`プロパティを持つ中央データモデル
  - 波形データ（512ポイント）、周波数（20-20000Hz）、音量、ポルタメント設定を含む
  - JSON永続化のため`Codable`を実装
  - プリセット波形（サイン波、三角波、矩形波）を生成

### ビューアーキテクチャ
- **ContentView.swift**: 4つのTrackインスタンスを`@StateObject`として管理するメインコンテナ
  - トラック選択を処理し、選択されたトラックを子ビューに渡す
- **WaveformDisplayView.swift**: タッチ描画機能付きのインタラクティブな波形表示
  - タッチ座標を512ポイントの波形データに変換
  - バインディングを通じてTrackモデルを直接更新
- **LiquidglassStyle.swift**: 一貫したグラスモーフィズムスタイリング用のカスタムUIモディファイアを定義

### データフロー
```
ユーザー入力 → Track @Published → ビュー更新
                    ↓
            JSON永続化（計画中）
```

### オーディオシステム（計画中）
AVAudioEngineを使用したオーディオエンジン：
- スレッドセーフのためのロックフリーパラメータキュー
- トラックごとの512ポイントウェーブテーブル合成
- 60Hzのパラメータ更新レート
- tanh(mixed * 0.7)によるソフトクリッピング

## 主要な実装詳細

### 波形描画
- WaveformDisplayViewでタッチジェスチャーをキャプチャ
- ポイントを512サンプルに補間
- [-1, 1]の範囲に正規化
- Track.waveformData配列に直接保存

### トラック管理
- ContentView内の4つの独立したTrackインスタンス
- 選択されたトラックインデックスがUI更新を駆動
- 各トラックが独自の状態（周波数、音量、波形）を維持

### UIスタイリング
- Liquidglassモディファイアが一貫したガラス効果を提供
- 青/紫のグラデーションを使用したダークテーマ
- ボタン押下状態に応じたシャドウ効果

## 現在のステータス

**完了**: UIフレームワーク、トラックモデル、波形表示、トラック切り替え、プリセット波形

**TODO**: AVAudioEngineを使用したオーディオエンジン実装、JSONへの永続化、周波数/音量コントロール