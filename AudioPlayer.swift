import AVFoundation

class AudioPlayer {
    private var player: AVAudioPlayer?
    
    func playNote(_ note: String) {
        guard let url = Bundle.main.url(forResource: note, withExtension: "wav") else {
            print("Could not find audio file for note: \(note).wav")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Audio playback failed: \(error.localizedDescription)")
        }
    }
}
