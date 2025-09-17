//
//  FormantFilter.swift
//  OscDrax
//
//  Multi-band formant filter for vowel and instrument simulation
//

import AVFoundation

class FormantFilter {
    private let eqNode: AVAudioUnitEQ
    private var currentType: FormantType = .none

    init() {
        // Create EQ with enough bands for formants (typically 3-4 bands)
        self.eqNode = AVAudioUnitEQ(numberOfBands: 4)

        // Initialize with bypass (no formant)
        setFormantType(.none)
    }

    var node: AVAudioNode {
        return eqNode
    }

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

        // Configure each band
        for (index, band) in eqNode.bands.enumerated() {
            if index < frequencies.count {
                // Configure as parametric EQ (bell curve)
                band.filterType = .parametric
                band.frequency = frequencies[index]
                band.bandwidth = 1.0 / qFactors[index]  // Q to bandwidth conversion
                band.gain = gains[index]
                band.bypass = false
            } else {
                // Bypass unused bands
                band.bypass = true
            }
        }

        // Set overall output gain to prevent clipping
        eqNode.globalGain = type.outputGain
    }

    func smoothTransition(to type: FormantType, duration: Float = 0.1) {
        // If transitioning to/from none, just switch immediately
        if type == .none || currentType == .none {
            setFormantType(type)
            return
        }

        // Get current and target parameters
        let currentFreqs = currentType.formantFrequencies
        let targetFreqs = type.formantFrequencies
        let targetQs = type.formantQFactors
        let targetGains = type.formantGains

        // Animate the transition
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