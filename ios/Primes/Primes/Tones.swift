//  Tones.swift — the story's music chapter, made audible. Plays only when you
//  tap play: a short buffer of soft plucked tones, synthesized on the spot.
//  The audio session is .ambient, so it mixes with whatever music is playing
//  (never pauses it) and stays quiet when the ringer switch is off.

import AVFoundation

final class Tones {
    static let shared = Tones()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let rate = 44_100.0
    private lazy var format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1)!
    private var ready = false

    struct Note { let freq: Double; let start: Double; let length: Double; var gain = 0.16 }

    /// The lower string, then the upper, then both together.
    static func interval(_ a: Int, _ b: Int, base: Double = 196) -> [Note] {
        let hi = base * Double(a) / Double(b)
        return [Note(freq: base, start: 0, length: 0.9), Note(freq: hi, start: 0.9, length: 0.9),
                Note(freq: base, start: 1.9, length: 1.6), Note(freq: hi, start: 1.9, length: 1.6)]
    }

    /// Two loops of a against b: a high tick for a, a low one for b.
    static func rhythm(_ a: Int, _ b: Int, bar: Double) -> [Note] {
        var out: [Note] = []
        for loop in 0..<2 {
            let t0 = Double(loop) * bar
            for k in 0..<a { out.append(Note(freq: 880, start: t0 + bar * Double(k) / Double(a), length: 0.12, gain: 0.2)) }
            for k in 0..<b { out.append(Note(freq: 330, start: t0 + bar * Double(k) / Double(b), length: 0.16, gain: 0.26)) }
        }
        return out
    }

    func play(_ notes: [Note]) {
        guard let end = notes.map({ $0.start + $0.length }).max() else { return }
        do {
            if !ready {
                try AVAudioSession.sharedInstance().setCategory(.ambient)
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                ready = true
            }
            try AVAudioSession.sharedInstance().setActive(true)
            if !engine.isRunning { try engine.start() }
        } catch { return }
        let frames = AVAudioFrameCount((end + 0.2) * rate)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buf.frameLength = frames
        let out = buf.floatChannelData![0]
        for i in 0..<Int(frames) { out[i] = 0 }
        for n in notes {
            let s0 = Int(n.start * rate), count = Int(n.length * rate)
            for i in 0..<count where s0 + i < Int(frames) {
                let t = Double(i) / rate
                let env = min(1, t / 0.008) * exp(-3.2 * t / n.length)           // a pluck: quick in, slow out
                let w = 2 * Double.pi * n.freq * t
                let v = sin(w) + 0.35 * sin(2 * w) + 0.12 * sin(3 * w)          // a few harmonics, so it sounds like a string
                out[s0 + i] += Float(v * env * n.gain)
            }
        }
        player.stop()
        player.scheduleBuffer(buf, at: nil)
        player.play()
    }

    func stop() { player.stop() }
}
