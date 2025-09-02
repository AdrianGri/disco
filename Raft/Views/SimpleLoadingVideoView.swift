//
//  SimpleLoadingVideoView.swift
//  Raft
//
//  Created by Adrian Gri on 2025-09-01.
//

import AVKit
import SwiftUI

// Video preloader singleton
class VideoPreloader: ObservableObject {
  static let shared = VideoPreloader()

  private var preloadedPlayers: [String: AVPlayer] = [:]

  private init() {}

  func preloadVideo(named videoName: String) {
    guard preloadedPlayers[videoName] == nil else {
      print("🔄 Video already preloaded: \(videoName)")
      return
    }

    print("🚀 Starting preload for: \(videoName)")

    guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4"),
      FileManager.default.fileExists(atPath: path)
    else {
      print("❌ Could not preload video: \(videoName).mp4")
      return
    }

    let url = URL(fileURLWithPath: path)
    let asset = AVAsset(url: url)

    // Load the asset metadata to ensure it's ready
    asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) {
      DispatchQueue.main.async {
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)

        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false

        // Observe player status to preroll when ready
        let statusObserver = player.observe(\.status, options: [.new]) { player, _ in
          DispatchQueue.main.async {
            if player.status == .readyToPlay {
              // Now it's safe to preroll
              player.seek(to: .zero)
              player.preroll(
                atRate: 1.0,
                completionHandler: { _ in
                  print("✅ Video preroll completed: \(videoName)")
                })
            }
          }
        }

        self.preloadedPlayers[videoName] = player
        print("✅ Preloaded video: \(videoName)")

        // Clean up observer after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
          statusObserver.invalidate()
        }
      }
    }
  }

  func getPlayer(for videoName: String) -> AVPlayer? {
    if let preloadedPlayer = preloadedPlayers[videoName] {
      print("🎯 Returning preloaded player for \(videoName)")

      // Reset the player to the beginning for fresh use
      preloadedPlayer.seek(to: .zero)

      return preloadedPlayer
    }
    print("❌ No preloaded player found for \(videoName)")
    return nil
  }

  func resetPlayer(for videoName: String) {
    if let player = preloadedPlayers[videoName] {
      player.pause()
      player.seek(to: .zero)
    }
  }
}

struct SimpleLoadingVideoView: View {
  let videoName: String
  @State private var player: AVPlayer?
  @State private var showVideo = false
  @State private var videoHasStarted = false
  @State private var allowVideoDisplay = false

  var body: some View {
    ZStack {
      // Always show background to prevent any flashing
      RoundedRectangle(cornerRadius: 12)
        .fill(.appBackground)
        .frame(width: 120, height: 120)

      if let player = player, showVideo && allowVideoDisplay {
        ZStack {
          // Video player
          VideoPlayer(player: player)
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .allowsHitTesting(false)

          // Overlay to hide black flash until video starts
          if !videoHasStarted {
            RoundedRectangle(cornerRadius: 12)
              .fill(.appBackground)
              .frame(width: 120, height: 120)
          }
        }
      } else {
        // Show loading indicator during slide-in and while video prepares
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.2))
          .frame(width: 120, height: 120)
          .overlay(
            ProgressView()
              .scaleEffect(0.8)
          )
      }
    }
    .onAppear {
      // Preload the video if not already preloaded
      VideoPreloader.shared.preloadVideo(named: videoName)

      // Reset state and setup player each time view appears
      cleanupPlayer()
      showVideo = false
      videoHasStarted = false
      allowVideoDisplay = false

      setupPlayer()

      // Allow video display immediately if we have a preloaded player, otherwise wait for slide-in
      if VideoPreloader.shared.getPlayer(for: videoName) != nil {
        print("⚡ Preloaded player available - showing immediately")
        allowVideoDisplay = true
      } else {
        print("⏱️ No preloaded player - waiting for slide-in animation")
        // Allow video display after slide-in animation completes (0.3s + small buffer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
          allowVideoDisplay = true
        }
      }
    }
    .onDisappear {
      cleanupPlayer()
    }
  }

  private func cleanupPlayer() {
    print("🧹 Cleaning up player")
    if let player = player {
      player.pause()
      // Reset the preloaded player for next use
      VideoPreloader.shared.resetPlayer(for: videoName)
    }
    player = nil
    NotificationCenter.default.removeObserver(self)
  }

  private func setupPlayer() {
    print("🎬 Setting up player for \(videoName)")

    // Try to get preloaded player first
    if let preloadedPlayer = VideoPreloader.shared.getPlayer(for: videoName) {
      print("⚡ Using preloaded player")
      self.player = preloadedPlayer

      // Set up looping for the preloaded player
      if let playerItem = preloadedPlayer.currentItem {
        NotificationCenter.default.addObserver(
          forName: .AVPlayerItemDidPlayToEndTime,
          object: playerItem,
          queue: .main
        ) { _ in
          print("🔄 Video ended, looping...")
          preloadedPlayer.seek(to: .zero)
          preloadedPlayer.play()
        }
      }

      // Add time observer
      preloadedPlayer.addPeriodicTimeObserver(
        forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main
      ) { time in
        if time.seconds > 0.05 && !self.videoHasStarted {
          print("🎬 Video has started playing, removing overlay")
          self.videoHasStarted = true
        }
      }

      // Start immediately since it's preloaded - no delay!
      print("🎥 Starting preloaded video immediately")
      self.showVideo = true
      preloadedPlayer.play()

      // For preloaded videos, assume they start quickly
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.videoHasStarted = true
      }
      return
    } else {
      print("❌ No preloaded player found, falling back to regular loading")
    }

    // Fallback to regular loading if preload failed
    print("📥 Falling back to regular loading")
    guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4"),
      FileManager.default.fileExists(atPath: path)
    else {
      print("❌ Video file not found: \(videoName).mp4")
      return
    }

    print("✅ Video file found at: \(path)")

    let url = URL(fileURLWithPath: path)
    let asset = AVAsset(url: url)
    let playerItem = AVPlayerItem(asset: asset)
    let newPlayer = AVPlayer(playerItem: playerItem)

    // Basic configuration
    newPlayer.isMuted = true

    // Store the player
    self.player = newPlayer
    print("📱 Player created and stored")

    // Observe when video actually starts playing to remove overlay
    newPlayer.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main
    ) { time in
      if time.seconds > 0.05 && !self.videoHasStarted {
        print("🎬 Video has started playing, removing overlay")
        self.videoHasStarted = true
      }
    }

    // Set up looping
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { _ in
      print("🔄 Video ended, looping...")
      newPlayer.seek(to: .zero)
      newPlayer.play()
    }

    // Show video player and start playing
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      print("🎥 Showing video and starting playback")
      self.showVideo = true
      newPlayer.play()
    }
  }
}

#Preview {
  SimpleLoadingVideoView(videoName: "loading_animation")
    .background(Color.gray.opacity(0.1))
}
