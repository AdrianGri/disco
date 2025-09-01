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
    if let player = player {
      VideoPlayer(player: player)
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
          player.play()
        }
        .onDisappear {
          player.pause()
        }
    } else {
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.2))
        .frame(width: 120, height: 120)
        .onAppear {
          setupPlayer()
        }
    }
  }

  private func setupPlayer() {
    // Try to load from main bundle first
    guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4"),
      FileManager.default.fileExists(atPath: path)
    else {
      print("Video file not found: \(videoName).mp4")
      return
    }

    let url = URL(fileURLWithPath: path)
    let playerItem = AVPlayerItem(url: url)
    player = AVPlayer(playerItem: playerItem)

    // Set up looping
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { _ in
      player?.seek(to: .zero)
      player?.play()
    }
  }
}

#Preview {
  SimpleLoadingVideoView(videoName: "loading_animation")
    .background(Color.gray.opacity(0.1))
}
