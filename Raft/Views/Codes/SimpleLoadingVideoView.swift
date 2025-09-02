//
//  SimpleLoadingVideoView.swift
//  Raft
//
//  Created by Adrian Gri on 2025-09-01.
//

import AVKit
import SwiftUI

struct SimpleLoadingVideoView: View {
  let videoName: String
  @State private var player: AVPlayer?

  var body: some View {
    ZStack {
      // Background
      RoundedRectangle(cornerRadius: 12)
        .fill(.appBackground)
        .frame(width: 120, height: 120)

      if let player = player {
        VideoPlayer(player: player)
          .frame(width: 120, height: 120)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .allowsHitTesting(false)
      } else {
        // Loading indicator
        ProgressView()
          .scaleEffect(0.8)
      }
    }
    .onAppear {
      setupPlayer()
    }
    .onDisappear {
      cleanupPlayer()
    }
  }

  private func setupPlayer() {
    guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4") else {
      return
    }

    let url = URL(fileURLWithPath: path)
    let playerItem = AVPlayerItem(url: url)
    let newPlayer = AVPlayer(playerItem: playerItem)

    newPlayer.isMuted = true
    self.player = newPlayer

    // Set up looping
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { _ in
      newPlayer.seek(to: .zero)
      newPlayer.play()
    }

    // Start playing
    newPlayer.play()
  }

  private func cleanupPlayer() {
    player?.pause()
    player = nil
    NotificationCenter.default.removeObserver(self)
  }
}

#Preview {
  SimpleLoadingVideoView(videoName: "loading_animation")
    .background(Color.gray.opacity(0.1))
}
