# CLAUDE.md

このリポジトリで作業する際は、必ず**日本語でレスポンス**してください。

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

OscDraxは音声波形を作成・操作するiOSオシレーターアプリケーションです。4つの独立したトラック、手描き波形作成、プリセット波形、リアルタイム周波数制御、AVAudioEngineベースのオーディオ合成を備えています。

## コマンド

```bash
# 開発
make lint          # SwiftLintでコードスタイルをチェック
make lint-fix      # SwiftLintで自動修正
make format        # SwiftLintでコードフォーマット（--fixと--formatフラグ付き）
make build         # Xcodeプロジェクトをビルド（macOS向けDebugビルド）
make clean         # ビルド成果物とDerivedDataをクリーン
make test          # ユニットテストを実行

# Xcodeで開く
open OscDrax.xcodeproj
```

## アーキテクチャ

### オーディオエンジン
- **AudioEngine.swift**: AVAudioEngineベースのオーディオ合成システム
  - 4つの独立したOscillatorNodeインスタンスをAVAudioMixerNodeで管理
  - AudioSessionの設定とエンジンのセットアップを処理
  - トラックごとの周波数、音量、波形、ポルタメント制御API

- **OscillatorNode.swift**: カスタムウェーブテーブルシンセサイザー実装
  - AVAudioSourceNodeを使用したリアルタイムオーディオ生成
  - 512ポイントのウェーブテーブル補間
  - ポルタメント（周波数スムージング）機能
  - ロックフリーのパラメータ更新キュー
  - フェーズアキュムレータによる高精度波形生成

### データモデル
- **Track.swift**: ObservableObjectプロトコルを実装した中央データモデル
  - 波形データ（512ポイント配列）
  - 周波数範囲: 20-20000Hz（対数スケール）
  - 音量: 0-1の範囲
  - ポルタメントタイム: 0-1秒
  - プリセット波形生成（サイン、三角、矩形、ノコギリ）
  - Codableプロトコルによる永続化対応

### 永続化
- **PersistenceManager.swift**: JSON形式でのトラックデータ保存/読み込み
  - Documentsディレクトリへの自動保存
  - 4トラックのバッチ保存/読み込み
  - エラーハンドリング付きファイル操作

### ビューアーキテクチャ
- **ContentView.swift**: アプリのメインコンテナビュー
  - 4つのTrackインスタンスを`@StateObject`として管理
  - AudioManagerとの統合
  - トラック選択とUI状態管理

- **WaveformDisplayView.swift**: インタラクティブな波形エディタ
  - ドラッグジェスチャーによる波形描画
  - リアルタイム波形プレビュー
  - 512ポイントへの自動補間

- **ControlPanelView.swift**: パラメータコントロールUI
  - 周波数スライダー（対数スケール）
  - 音量コントロール
  - ポルタメントタイム調整

### SwiftLint設定
`.swiftlint.yml`による厳格なコード品質管理：
- 85以上のopt-inルールを有効化
- カスタムルール（print文の禁止、MARKフォーマット）
- アナライザールール（未使用宣言、未使用import）
- 関数長、型長、複雑度の制限

## 重要な実装パターン

### スレッドセーフティ
- AudioEngineとUIスレッド間の適切な同期
- DispatchQueueによるパラメータ更新の管理
- ロックフリーキューによるオーディオスレッド最適化

### メモリ管理
- weak参照によるretain cycle回避
- deinitでの適切なリソース解放
- AVAudioEngineの明示的な停止処理

## 現在のステータス

**実装済み**:
- 完全なUIフレームワーク
- 4トラックシステム
- AVAudioEngineオーディオ合成
- ウェーブテーブル合成
- JSON永続化
- ポルタメント機能
- プリセット波形

**進行中/TODO**:
- MiniWaveformView（トラックタブ用のミニ波形表示）
- 追加のエフェクト処理
- MIDI対応（将来的な拡張）