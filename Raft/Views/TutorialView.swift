//
//  TutorialView.swift
//  Raft
//
//  Created by Adrian Gri on 2025-09-20.
//

import AVKit
import SwiftUI

struct TutorialView: View {
  @Binding var isPresented: Bool
  @State private var player: AVPlayer?
  @State private var isPlayerReady = false
  @State private var playerStatusObserver: NSKeyValueObservation?

  var body: some View {
    ZStack {
      // Background
      Color.appBackground
        .ignoresSafeArea()

      VStack(spacing: 20) {
        // Title
        Text("Welcome to Disco!")
          .font(.custom("Avenir", size: 32))
          .fontWeight(.bold)
          .foregroundColor(.primary)

        // Video area
        ZStack {
          // Placeholder / loader until ready
          if !isPlayerReady {
            ProgressView()
              .frame(width: 300, height: 576)
          }

          if let player = player {
            VideoPlayer(player: player)
              .frame(width: 300, height: 576)
              .cornerRadius(12)
              .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
              .allowsHitTesting(false)
              .opacity(isPlayerReady ? 1 : 0)
          }
        }

        Spacer()

        // Continue button
        Button {
          isPresented = false
        } label: {
          Text("Get Started")
            .foregroundColor(.appAccent)
            .padding()
            .frame(maxWidth: 250)
            .background(.appPrimary)
            .cornerRadius(10)
            .fontWeight(.semibold)
        }
      }
      .padding(.vertical, 60)
    }
    .onAppear {
      setupPlayer()
    }
    .onDisappear {
      cleanupPlayer()
    }
  }

  private func setupPlayer() {
    guard let path = Bundle.main.path(forResource: "tutorial", ofType: "mov") else {
      return
    }

    let url = URL(fileURLWithPath: path)
    let playerItem = AVPlayerItem(url: url)
    let newPlayer = AVPlayer(playerItem: playerItem)

    newPlayer.isMuted = true
    newPlayer.automaticallyWaitsToMinimizeStalling = false
    self.player = newPlayer

    // Observe readiness to avoid flashing a black rectangle
    playerStatusObserver = playerItem.observe(\.status, options: [.initial, .new]) { _, _ in
      if playerItem.status == .readyToPlay {
        DispatchQueue.main.async {
          isPlayerReady = true
          newPlayer.play()
        }
      }
    }

    // Set up looping
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { _ in
      newPlayer.seek(to: .zero)
      newPlayer.play()
    }
  }

  private func cleanupPlayer() {
    player?.pause()
    player = nil
    isPlayerReady = false
    playerStatusObserver?.invalidate()
    playerStatusObserver = nil
    NotificationCenter.default.removeObserver(self)
  }
}

#Preview {
  TutorialView(isPresented: .constant(true))
}
