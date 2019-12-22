//
//  Synthesizer.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 15.10.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation
import AVFoundation

final class Synthesizer {
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private static let sampleRate = 44100.0
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Synthesizer.sampleRate, channels: 1)
    
    init() {
        
        configureEngine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(Synthesizer.audioEngineConfigurationChange(_:)), name: NSNotification.Name.AVAudioEngineConfigurationChange, object: audioEngine)
    }
    deinit {
        audioEngine.stop()
    }
    
    func playScaledContent(_ content: AudioInformation) {
        let generator = SoundGenerator(sampleRate: Synthesizer.sampleRate)

        let finalBuffer = generator.sweep(content)
        
        configureBufferAndPlay(finalBuffer)
    }
    
    private func configureBufferAndPlay(_ bufferContent: [Float]) {
        startEngineIfNeeded()
        
        let numberOfSamples = AVAudioFrameCount(bufferContent.count)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: numberOfSamples)!
        buffer.frameLength = numberOfSamples
        let leftChannel = buffer.floatChannelData?[0]
        let rightChannel = buffer.floatChannelData?[1]
        // Copy into the buffer:
        for (index, sample) in bufferContent.enumerated() {
            leftChannel?[index] = sample
            rightChannel?[index] = sample
        }
        playerNode.scheduleBuffer(buffer) {
            print("Completed")
        }
        
        playerNode.play()
    }
    
    private func startEngineIfNeeded() {
        guard !audioEngine.isRunning else { return }
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine didn't start")
        }
    }
    
    private func configureEngine() {
        audioEngine.reset()
        
        // Attach and connect the player node.
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.prepare()
    }
    
    @objc  func audioEngineConfigurationChange(_ notification: Notification) -> Void {
        configureEngine()
    }
}
