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
    /// Called when playing the audio samples has completed with `true`, when stopped or an error occured with argument set to `false`. Called on the main queue. Will be discarded when called once.
    var completion: ((_ success: Bool) -> Void)?
    var volumeCorrectionFactor: Float32 = 1.0
    
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
        callCompletionAndRemove(with: false)
    }
    
    /// Expects scaled audio information that already have the correct duration and frequencies.
    ///
    /// That data will be converted into sound samples.
    /// When done, the samples are played using the main queue.
    /// - Parameters:
    ///   - content: In time and frequency preprocessed audio information.
    func playScaledContent(_ content: AudioInformation) {
        let generator = SoundGenerator(sampleRate: Synthesizer.sampleRate, volumeCorrectionFactor: self.volumeCorrectionFactor)
        
        let finalBuffer = generator.sweep(content)
        
        // Play the sound on the main queue.
        DispatchQueue.main.async {
            self.configureBufferAndPlay(finalBuffer)
        }
    }
    
    /// Stops the playback immediately and calls the completion-block with argument `false`.
    func stop() {
        playerNode.stop()
        callCompletionAndRemove(with: false)
    }
    
    private func configureBufferAndPlay(_ bufferContent: Samples) {
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
            DispatchQueue.main.async { [weak self] in
                self?.callCompletionAndRemove(with: true)
            }
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
        callCompletionAndRemove(with: false)
        
        // Attach and connect the player node.
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.prepare()
    }
    
    @objc func audioEngineConfigurationChange(_ notification: Notification) -> Void {
        configureEngine()
    }
    
    private func callCompletionAndRemove(with argument: Bool) {
        completion?(argument)
        completion = nil
    }
}
