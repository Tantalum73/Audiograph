//
//  Synthesizer.swift
//  ChartAndSound
//
//  Created by Andreas Neusüß on 15.10.19.
//  Copyright © 2019 Anerma. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

/// This class plays `AudioInformation` that it receives through a call to `Synthesizer.playScaledContent(_:)`. The content needs to be scaled in frequency and time. Corresponding samples will be derived and played.
///
/// It's possible to specify for example the phrase that is read when playing the Audiograph is completed or providing a custom loudness-factor.
///
/// Stoppable by receiving a notification with name `Notification.Name.stopAudiograph`.
final class Synthesizer: NSObject {
    /// Called when playing the audio samples has completed with `true`, when stopped or an error occured with argument set to `false`. Called on the main queue. Will be discarded when called once.
    var completion: ((_ success: Bool) -> Void)?
    var volumeCorrectionFactor: Double = 1.0
    
    /// This word is read after the Audiograph has finished playing.
    var completionIndicationString: String = "Complete"
    
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private static let sampleRate = 44100.0
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Synthesizer.sampleRate, channels: 1)
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var completionUtterance: AVSpeechUtterance {
        AVSpeechUtterance(string: completionIndicationString)
    }
    /// Delay between speaking the `completionIndicationUtterance` and the end of the Audiograph playback.
    private let completionSpeachDelay: Double = 0.5
    private var stoppedByUser = false
    
    override init() {
        super.init()
        
        configureEngine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(Synthesizer.audioEngineConfigurationChange(_:)), name: .AVAudioEngineConfigurationChange, object: audioEngine)
        NotificationCenter.default.addObserver(self, selector: #selector(Synthesizer.stop), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Synthesizer.stop), name: .stopAudiograph, object: nil)
        
        speechSynthesizer.delegate = self
    }
    
    deinit {
        audioEngine.stop()
    }
    
    /// Expects scaled audio information that already have the correct duration and frequencies.
    ///
    /// That data will be converted into sound samples.
    /// When done, the samples are played using the main queue.
    /// - Parameters:
    ///   - content: In time and frequency preprocessed audio information.
    func playScaledContent(_ content: AudioInformation) {
        stoppedByUser = false
        let generator = SoundGenerator(sampleRate: Synthesizer.sampleRate, volumeCorrectionFactor: self.volumeCorrectionFactor)
        
        let finalBuffer = generator.sweep(content)
        
        
        
        // Play the sound on the main queue.
        DispatchQueue.main.async {
            self.configureBufferAndPlay(finalBuffer)
        }
    }
    
    /// Stops the playback immediately and calls the completion-block with argument `false`.
    @objc func stop() {
        stoppedByUser = true
        playerNode.stop()
        callCompletionAndReset(completedSuccessfully: false)
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
            // Converting to Float at the latest possible moment:
            leftChannel?[index] = Float32(sample)
            rightChannel?[index] = Float32(sample)
        }
        playerNode.scheduleBuffer(buffer) {
            Logger.shared.log(message: "Complete.")
            if !self.stoppedByUser {
                self.readDelayedCompletionUtterance()
            }
        }
        
        playerNode.play()
    }
    
    private func readDelayedCompletionUtterance() {
        guard !completionIndicationString.isEmpty, volumeCorrectionFactor != 0 else {
            callCompletionAndReset(completedSuccessfully: true)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + completionSpeachDelay) {
            self.speechSynthesizer.speak(self.completionUtterance)
        }
    }
    
    private func startEngineIfNeeded() {
        // When connected, the users audio will pause. Do that at the latest possible.
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.prepare()
        
        guard !audioEngine.isRunning else { return }
        do {
            try audioEngine.start()
        } catch {
            Logger.shared.log(message: "AudioEngine didn't start")
        }
    }
    
    private func configureEngine() {
        audioEngine.reset()
        callCompletionAndReset(completedSuccessfully: false)
        
        // Attach and connect the player node.
        audioEngine.attach(playerNode)
    }
    
    @objc func audioEngineConfigurationChange(_ notification: Notification) -> Void {
        configureEngine()
    }
    
    private func callCompletionAndReset(completedSuccessfully argument: Bool) {
        DispatchQueue.main.async {
            self.completion?(argument)
            self.completion = nil
        }
    }
}

extension Synthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        callCompletionAndReset(completedSuccessfully: true)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        callCompletionAndReset(completedSuccessfully: false)
    }
}
