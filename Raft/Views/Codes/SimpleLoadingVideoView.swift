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
  @State private var isReady: Bool = false
  @State private var statusObserver: NSKeyValueObservation?
  @State private var playbackObserver: NSObjectProtocol?

  var body: some View {
    ZStack {
      // Background
      RoundedRectangle(cornerRadius: 12)
        .fill(.appBackground)
        .frame(width: 120, height: 120)

      // Always show progress while not ready
      if !isReady {
        ProgressView()
          .scaleEffect(0.8)
      }

      // Only show video when ready
      if let player = player {
        VideoPlayer(player: player)
          .frame(width: 120, height: 120)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .allowsHitTesting(false)
          .opacity(isReady ? 1 : 0)
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
    newPlayer.automaticallyWaitsToMinimizeStalling = false
    self.player = newPlayer

    // Observe readiness
    statusObserver = playerItem.observe(\.status, options: [.initial, .new]) { [weak newPlayer] item, _ in
      if item.status == .readyToPlay {
        DispatchQueue.main.async {
          self.isReady = true
          newPlayer?.play()
        }
      }
    }

    // Set up looping
    playbackObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { [weak newPlayer] _ in
      newPlayer?.seek(to: .zero)
      newPlayer?.play()
    }
  }

  private func cleanupPlayer() {
    player?.pause()
    player = nil
    isReady = false
    statusObserver?.invalidate()
    statusObserver = nil
    if let token = playbackObserver {
      NotificationCenter.default.removeObserver(token)
    }
    playbackObserver = nil
  }
}

#Preview {
  SimpleLoadingVideoView(videoName: "loading_animation")
    .background(Color.gray.opacity(0.1))
}
