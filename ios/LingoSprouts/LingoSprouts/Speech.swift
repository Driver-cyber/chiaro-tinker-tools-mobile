//  Speech.swift — read the question aloud, for younger and newer readers.
//  AVSpeechSynthesizer uses the phone's built-in voices, so it works offline.

import AVFoundation

enum Speech {
    private static let synth = AVSpeechSynthesizer()

    static func say(_ text: String) {
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(u)
    }
}
