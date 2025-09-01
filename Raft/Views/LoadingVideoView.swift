//
//  LoadingVideoView.swift
//  Raft
//
//  Created by Adrian Gri on 2025-09-01.
//

import AVKit
import SwiftUI

struct LoadingVideoView: View {
  let videoName: String
  @State private var player: AVPlayer?

  var body: some View {
    VideoPlayerView(player: player)
      .aspectRatio(contentMode: .fit)
      .frame(width: 100, height: 100)  // Adjust size as needed
      .onAppear {
        setupPlayer()
      }
      .onDisappear {
        player?.pause()
      }
  }

  private func setupPlayer() {
    guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4") else {
      print("Video file not found: \(videoName).mp4")
      return
    }

    let url = URL(fileURLWithPath: path)
    player = AVPlayer(url: url)

    // Set up looping
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: player?.currentItem,
      queue: .main
    ) { _ in
      player?.seek(to: .zero)
      player?.play()
    }

    player?.play()
  }
}

// Custom VideoPlayer wrapper for better control
struct VideoPlayerView: UIViewRepresentable {
  let player: AVPlayer?

  func makeUIView(context: Context) -> UIView {
    let view = UIView()

    guard let player = player else { return view }

    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.videoGravity = .resizeAspect
    view.layer.addSublayer(playerLayer)

    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    guard let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer else { return }
    playerLayer.frame = uiView.bounds
  }
}

#Preview {
  LoadingVideoView(videoName: "loading_animation")
    .background(Color.gray.opacity(0.1))
}
