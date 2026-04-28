#if os(macOS)
import AVFoundation
import AudioToolbox
import Foundation

final class AlarmController {
    private var player: AVAudioPlayer?
    private var storedVolume: Float?

    func startAlarm() {
        guard player?.isPlaying != true else { return }

        if storedVolume == nil {
            storedVolume = SystemVolumeController.currentOutputVolume()
        }

        do {
            let alarmURL = try AlarmToneFactory.sharedAlarmURL()
            let player = try AVAudioPlayer(contentsOf: alarmURL)
            player.numberOfLoops = -1
            player.volume = 1.0
            player.prepareToPlay()

            SystemVolumeController.setOutputVolume(1.0)

            self.player = player
            player.play()
        } catch {
            SystemVolumeController.setOutputVolume(1.0)
        }
    }

    func stopAlarm() {
        player?.stop()
        player = nil

        if let storedVolume {
            SystemVolumeController.setOutputVolume(storedVolume)
        }

        storedVolume = nil
    }
}

enum AlarmToneFactory {
    static func sharedAlarmURL() throws -> URL {
        let fileManager = FileManager.default
        let baseDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let appDirectory = baseDirectory.appendingPathComponent("SafeLid", isDirectory: true)
        try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        let audioURL = appDirectory.appendingPathComponent("Alarm.wav")
        if !fileManager.fileExists(atPath: audioURL.path) {
            try writeSirenWav(to: audioURL)
        }

        return audioURL
    }

    private static func writeSirenWav(to url: URL) throws {
        let sampleRate = 44_100
        let durationSeconds = 1.2
        let frameCount = Int(Double(sampleRate) * durationSeconds)
        let bitsPerSample = 16
        let channels = 1
        let bytesPerSample = bitsPerSample / 8
        let byteRate = sampleRate * channels * bytesPerSample
        let blockAlign = channels * bytesPerSample

        var pcm = Data()
        pcm.reserveCapacity(frameCount * bytesPerSample)

        for frame in 0..<frameCount {
            let time = Double(frame) / Double(sampleRate)
            let sweep = (sin(time * .pi * 2.0 * 0.8) + 1.0) * 0.5
            let frequency = 760.0 + sweep * 480.0
            let amplitude = 0.70
            let sample = sin(2.0 * .pi * frequency * time) * amplitude
            let clamped = max(-1.0, min(1.0, sample))
            let intSample = Int16(clamped * Double(Int16.max))

            var littleEndian = intSample.littleEndian
            Swift.withUnsafeBytes(of: &littleEndian) { pcm.append(contentsOf: $0) }
        }

        var wav = Data()
        wav.appendASCII("RIFF")
        wav.appendUInt32LE(UInt32(36 + pcm.count))
        wav.appendASCII("WAVE")
        wav.appendASCII("fmt ")
        wav.appendUInt32LE(16)
        wav.appendUInt16LE(1)
        wav.appendUInt16LE(UInt16(channels))
        wav.appendUInt32LE(UInt32(sampleRate))
        wav.appendUInt32LE(UInt32(byteRate))
        wav.appendUInt16LE(UInt16(blockAlign))
        wav.appendUInt16LE(UInt16(bitsPerSample))
        wav.appendASCII("data")
        wav.appendUInt32LE(UInt32(pcm.count))
        wav.append(pcm)

        try wav.write(to: url, options: .atomic)
    }
}

enum SystemVolumeController {
    static func currentOutputVolume() -> Float {
        guard let deviceID = defaultOutputDeviceID() else { return 1.0 }

        var volume = Float32(1.0)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        return status == noErr ? max(0, min(1, volume)) : 1.0
    }

    static func setOutputVolume(_ value: Float) {
        let clamped = max(0, min(1, value))

        guard let deviceID = defaultOutputDeviceID() else {
            fallbackAppleScriptVolume(clamped)
            return
        }

        var volume = Float32(clamped)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &volume)

        if status != noErr {
            fallbackAppleScriptVolume(clamped)
        }
    }

    private static func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        return status == noErr && deviceID != 0 ? deviceID : nil
    }

    private static func fallbackAppleScriptVolume(_ value: Float) {
        let percentage = Int((value * 100).rounded())
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", "set volume output volume \(percentage)"]
        try? task.run()
    }
}

private extension Data {
    mutating func appendASCII(_ text: String) {
        if let bytes = text.data(using: .ascii) {
            append(bytes)
        }
    }

    mutating func appendUInt16LE(_ value: UInt16) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
#endif
