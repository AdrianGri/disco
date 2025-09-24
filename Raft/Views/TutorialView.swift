//
//  TutorialView.swift
//  Raft
//
//  Created by Adrian Gri on 2025-09-20.
//

import AVKit
import SwiftUI

struct TutorialView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var currentPage = 0
  @State private var didComplete = false

  // First page (tutorial.mov) state
  @State private var firstPlayer: AVPlayer?
  @State private var isFirstPlayerReady = false
  @State private var firstPlayerStatusObserver: NSKeyValueObservation?

  // Second page (safari_tutorial.mov) state
  @State private var secondPlayer: AVPlayer?
  @State private var isSecondPlayerReady = false
  @State private var secondPlayerStatusObserver: NSKeyValueObservation?

  var body: some View {
    NavigationView {
      ZStack {
        // Background
        Color.appBackground.ignoresSafeArea()

        TabView(selection: $currentPage) {
          // First Page - tutorial.mov
          tutorialPageView(
            title: "Welcome to Disco!",
            player: firstPlayer,
            isReady: isFirstPlayerReady
          )
          .tag(0)

          // Second Page - safari_tutorial.mov
          tutorialPageView(
            title: "Use Disco in Safari!",
            player: secondPlayer,
            isReady: isSecondPlayerReady
          )
          .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.5), value: currentPage)
        .overlay(alignment: .bottom) {
          VStack(spacing: 12) {
            // Page indicator dots
            HStack(spacing: 8) {
              Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(currentPage == 0 ? .appAccent : .black.opacity(0.3))
              Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(currentPage == 1 ? .appAccent : .black.opacity(0.3))
            }
            .animation(.easeInOut(duration: 0.2), value: currentPage)

            // Stationary bottom button
            Button {
              if currentPage == 0 {
                withAnimation(.easeInOut(duration: 0.5)) {
                  currentPage = 1
                }
              } else {
                completeAndDismiss()
              }
            } label: {
              ZStack {
                Text("Next")
                  .opacity(currentPage == 0 ? 1.0 : 0.0)
                Text("Start Saving")
                  .opacity(currentPage == 1 ? 1.0 : 0.0)
              }
              .foregroundColor(.appAccent)
              .padding(.vertical, 14)
              .padding(.horizontal, 20)
              .frame(maxWidth: 250)
              .background(.appPrimary)
              .cornerRadius(10)
              .fontWeight(.semibold)
              .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 24)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
    }
    .interactiveDismissDisabled(true)
    .onAppear {
      setupPlayers()
    }
    .onDisappear {
      cleanupPlayers()
      // Handle swipe-to-dismiss: ensure completion flow runs exactly once
      if !didComplete {
        completeAndDismiss()
      }
    }
    .onChange(of: currentPage) { newPage in
      handlePageChange(newPage)
    }
  }

  @ViewBuilder
  private func tutorialPageView(
    title: String,
    player: AVPlayer?,
    isReady: Bool
  ) -> some View {
    GeometryReader { geo in
      // Known video size: 500(w) x 960(h) => aspect w/h = 500/960 (~0.5208)
      // Compute the largest width that fits both horizontally and vertically.
      let aspectWOverH: CGFloat = 500.0 / 960.0
      let horizontalCap = geo.size.width - 32  // account for our horizontal padding
      // Reserve vertical space for title, spacing, button, and padding conservatively
      let reservedVertical: CGFloat = 180
      let availableHeight = max(0, geo.size.height - reservedVertical)
      // Given height = width / aspectWOverH => width = height * aspectWOverH
      let verticalCap = availableHeight * aspectWOverH
      // Allow up to 320pt width when space allows, else constrained by device
      let maxWidth: CGFloat = max(0, min(horizontalCap, verticalCap, 320))
      let height: CGFloat = (maxWidth > 0) ? (maxWidth / aspectWOverH) : 0

      VStack(spacing: 16) {
        // Title
        Text(title)
          .font(.custom("Avenir", size: 28))
          .fontWeight(.bold)
          .foregroundColor(.primary)
          .multilineTextAlignment(.center)

        // Video area sized exactly to aspect ratio
        ZStack {
          // Placeholder / loader until ready
          if !isReady {
            ProgressView()
              .frame(width: maxWidth, height: height)
          }

          if let player = player {
            VideoPlayer(player: player)
              .frame(width: maxWidth, height: height)
              .cornerRadius(12)
              .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
              .allowsHitTesting(false)
              .opacity(isReady ? 1 : 0)
          }
        }

        Spacer(minLength: 10)
      }
      .padding(.vertical, 20)
      .padding(.horizontal, 16)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
  }

  private func completeAndDismiss() {
    guard !didComplete else { return }
    didComplete = true
    // Mark as seen and kick off privacy+ads flow, then dismiss
    appState.markTutorialAsSeen()
    Task {
      await appState.requestTrackingPermissionIfNeeded()
      appState.startMobileAds()
    }
    dismiss()
  }

  private func setupPlayers() {
    setupFirstPlayer()
    setupSecondPlayer()
  }

  private func setupFirstPlayer() {
    guard let path = Bundle.main.path(forResource: "tutorial", ofType: "mov") else {
      print("❌ Could not find tutorial.mov")
      return
    }

    let url = URL(fileURLWithPath: path)
    let playerItem = AVPlayerItem(url: url)
    let newPlayer = AVPlayer(playerItem: playerItem)

    newPlayer.isMuted = true
    newPlayer.automaticallyWaitsToMinimizeStalling = false
    self.firstPlayer = newPlayer

    // Observe readiness to avoid flashing a black rectangle
    firstPlayerStatusObserver = playerItem.observe(\.status, options: [.initial, .new]) { _, _ in
      if playerItem.status == .readyToPlay {
        DispatchQueue.main.async {
          self.isFirstPlayerReady = true
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

  private func setupSecondPlayer() {
    guard let path = Bundle.main.path(forResource: "safari_tutorial", ofType: "mov") else {
      print("❌ Could not find safari_tutorial.mov")
      return
    }

    let url = URL(fileURLWithPath: path)
    let playerItem = AVPlayerItem(url: url)
    let newPlayer = AVPlayer(playerItem: playerItem)

    newPlayer.isMuted = true
    newPlayer.automaticallyWaitsToMinimizeStalling = false
    self.secondPlayer = newPlayer

    // Observe readiness to avoid flashing a black rectangle
    secondPlayerStatusObserver = playerItem.observe(\.status, options: [.initial, .new]) { _, _ in
      if playerItem.status == .readyToPlay {
        DispatchQueue.main.async {
          self.isSecondPlayerReady = true
          // Only start playing if we're on the second page
          if self.currentPage == 1 {
            newPlayer.play()
          }
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

  private func cleanupPlayers() {
    // Cleanup first player
    firstPlayer?.pause()
    firstPlayer = nil
    isFirstPlayerReady = false
    firstPlayerStatusObserver?.invalidate()
    firstPlayerStatusObserver = nil

    // Cleanup second player
    secondPlayer?.pause()
    secondPlayer = nil
    isSecondPlayerReady = false
    secondPlayerStatusObserver?.invalidate()
    secondPlayerStatusObserver = nil

    NotificationCenter.default.removeObserver(self)
  }

  private func handlePageChange(_ newPage: Int) {
    if newPage == 0 {
      // On first page - play first video, pause second
      if isFirstPlayerReady {
        firstPlayer?.play()
      }
      secondPlayer?.pause()
    } else if newPage == 1 {
      // On second page - play second video, pause first
      firstPlayer?.pause()
      if isSecondPlayerReady {
        secondPlayer?.play()
      }
    }
  }
}

#Preview {
  TutorialView()
    .environmentObject(AppState())
}
