//  Speech.swift — reading aloud, politely.
//
//  Lesson from Number Sprouts: a speech voice that just starts talking pauses
//  whatever music the phone is playing. Here speech only happens when a kid
//  taps a speaker (or a grown-up turns on "Read aloud"), it ducks other audio
//  instead of pausing it, and it gives the volume back the moment it's done.
//  The phone's built-in voices work offline. It also reports which word is
//  being spoken, so a story can light up word by word.

import AVFoundation
import Combine

final class Reader: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = Reader()

    /// The range of the text being spoken right now, or nil when quiet.
    @Published private(set) var speaking: NSRange?
    @Published private(set) var text = ""

    private let synth = AVSpeechSynthesizer()

    override init() {
        super.init()
        synth.delegate = self
    }

    func say(_ s: String) {
        synth.stopSpeaking(at: .immediate)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
        text = s
        let u = AVSpeechUtterance(string: s)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(u)
    }

    func stop() { synth.stopSpeaking(at: .immediate) }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, willSpeakRangeOfSpeechString r: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.speaking = r }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { finished() }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { finished() }

    private func finished() {
        DispatchQueue.main.async { self.speaking = nil }
        // Hand the volume back to whatever was playing.
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
