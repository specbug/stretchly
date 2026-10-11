import AVFoundation

@MainActor
final class SoundPlayer {
  private var player: AVAudioPlayer?

  func play(_ name: String) {
    guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
    try? AVAudioSession.sharedInstance().setCategory(.ambient)
    player = try? AVAudioPlayer(contentsOf: url)
    player?.play()
  }
}
