import Foundation
import Combine

/// シンセサイザ関連で共通利用する定数群。
public enum SynthConstants {
    /// デフォルトの波形サンプル数。
    public static let defaultWaveformSampleCount = 512
}

/// オーディオエンジンへ渡すトラックパラメータのスナップショット。
public struct SynthTrackParameters: Equatable {
    public let id: Int
    public var waveformType: WaveformType
    public var waveformData: [Float]
    public var frequency: Float
    public var volume: Float
    public var isPlaying: Bool
    /// ポルタメント時間 (ミリ秒 / 0〜1000 の範囲)。
    public var portamentoTime: Float
    public var harmonyEnabled: Bool
    public var assignedInterval: HarmonyInterval?
    public var isHarmonyLead: Bool
    public var vibratoEnabled: Bool
    public var scaleType: ScaleType

    public init(
        id: Int,
        waveformType: WaveformType,
        waveformData: [Float],
        frequency: Float,
        volume: Float,
        isPlaying: Bool,
        portamentoTime: Float,
        harmonyEnabled: Bool,
        assignedInterval: HarmonyInterval?,
        isHarmonyLead: Bool,
        vibratoEnabled: Bool,
        scaleType: ScaleType
    ) {
        self.id = id
        self.waveformType = waveformType
        self.waveformData = waveformData
        self.frequency = frequency
        self.volume = volume
        self.isPlaying = isPlaying
        self.portamentoTime = portamentoTime
        self.harmonyEnabled = harmonyEnabled
        self.assignedInterval = assignedInterval
        self.isHarmonyLead = isHarmonyLead
        self.vibratoEnabled = vibratoEnabled
        self.scaleType = scaleType
    }
}

/// 全体設定（コード種別・フォルマントなど）を保持する構造体。
public struct SynthGlobalState {
    public var chordType: ChordType
    public var formantType: FormantType

    public init(chordType: ChordType, formantType: FormantType) {
        self.chordType = chordType
        self.formantType = formantType
    }
}

/// サイレントスイッチへの追従ポリシー。
public enum SynthSilentModePolicy {
    case ignoresMuteSwitch
    case respectsMuteSwitch
}

/// ハーモニー更新結果を UI へ通知するための構造体。
public struct SynthTrackFrequencyUpdate {
    public let trackID: Int
    public let frequency: Float
    public let assignedInterval: HarmonyInterval?

    public init(trackID: Int, frequency: Float, assignedInterval: HarmonyInterval?) {
        self.trackID = trackID
        self.frequency = frequency
        self.assignedInterval = assignedInterval
    }
}

/// 音声合成エンジンが備えるべきインターフェイス定義。
public protocol SynthEngineProtocol: AnyObject {
    /// 現在のフォルマント種別。
    var formantType: FormantType { get set }
    /// フォルマント変更を監視するためのパブリッシャ。
    var formantTypePublisher: AnyPublisher<FormantType, Never> { get }
    /// サイレントモードの扱い。
    var silentModePolicy: SynthSilentModePolicy { get set }

    /// オーディオセッションを構成します。
    func configureAudioSession()
    /// オーディオセッションを無効化します。
    func deactivateAudioSession()
    /// アプリが非アクティブになる直前のハンドリング。
    func handleWillResignActive()
    /// バックグラウンド遷移時のハンドリング。
    func handleDidEnterBackground()
    /// フォアグラウンド復帰時のハンドリング。
    func handleWillEnterForeground()
    /// アクティブ復帰時のハンドリング。
    func handleDidBecomeActive()
    /// 必要であればエンジンを起動します。
    func startEngineIfNeeded()

    /// 新しいトラックをエンジンに登録します。
    func registerTrack(_ parameters: SynthTrackParameters)
    /// 既存トラックのパラメータを更新します。
    func updateTrack(_ parameters: SynthTrackParameters)
    /// 再生状態を切り替えます。
    func setTrackIsPlaying(_ trackID: Int, isPlaying: Bool)

    /// ハーモニー用の周波数を更新し、変更結果を返します。
    func updateHarmonyFrequencies(
        leadTrack: SynthTrackParameters,
        allTracks: [SynthTrackParameters],
        chordType: ChordType
    ) -> [SynthTrackFrequencyUpdate]
}
