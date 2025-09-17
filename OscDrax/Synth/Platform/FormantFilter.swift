import AVFoundation

/// `AVAudioUnitEQ` を用いてフォルマント特性を付与するフィルタクラス。
class FormantFilter {
    private let eqNode: AVAudioUnitEQ
    private var currentType: FormantType = .none

    /// 指定のフォルマント数に対応した EQ を生成します。
    init() {
        self.eqNode = AVAudioUnitEQ(numberOfBands: 4)

        setFormantType(.none)
    }

    /// 内部で利用している EQ ノードを返します。
    var node: AVAudioNode {
        return eqNode
    }

    /// フォルマント種別を即時適用します。
    func setFormantType(_ type: FormantType) {
        currentType = type
        if type == .none {
            eqNode.bypass = true
        } else {
            eqNode.bypass = false
            setupFormant(type)
        }
    }

    private func setupFormant(_ type: FormantType) {
        let frequencies = type.formantFrequencies
        let qFactors = type.formantQFactors
        let gains = type.formantGains

        for (index, band) in eqNode.bands.enumerated() {
            if index < frequencies.count {
                band.filterType = .parametric
                band.frequency = frequencies[index]
                band.bandwidth = 1.0 / qFactors[index]  // Q to bandwidth conversion
                band.gain = gains[index]
                band.bypass = false
            } else {
                band.bypass = true
            }
        }

        eqNode.globalGain = type.outputGain
    }

    /// フォルマントを滑らかに遷移させます。
    /// - Parameters:
    ///   - type: 目標のフォルマント種別。
    ///   - duration: 遷移にかける秒数。
    func smoothTransition(to type: FormantType, duration: Float = 0.1) {
        if type == .none || currentType == .none {
            setFormantType(type)
            return
        }

        let currentFreqs = currentType.formantFrequencies
        let targetFreqs = type.formantFrequencies
        let targetQs = type.formantQFactors
        let targetGains = type.formantGains

        let steps = 10
        let stepDuration = duration / Float(steps)

        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stepDuration * Float(step))) { [weak self] in
                guard let self = self else { return }

                let progress = Float(step + 1) / Float(steps)

                for (index, band) in self.eqNode.bands.enumerated() {
                    if index < targetFreqs.count && index < currentFreqs.count {
                        // Interpolate frequency
                        let currentFreq = currentFreqs[index]
                        let targetFreq = targetFreqs[index]
                        band.frequency = currentFreq + (targetFreq - currentFreq) * progress

                        // Set final Q and gain (no interpolation for stability)
                        if step == steps - 1 {
                            band.bandwidth = 1.0 / targetQs[index]
                            band.gain = targetGains[index]
                        }
                    }
                }

                if step == steps - 1 {
                    self.currentType = type
                    self.eqNode.globalGain = type.outputGain
                }
            }
        }
    }
}
