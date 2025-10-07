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

  // Video controllers
  @StateObject private var firstController = LoopingVideoController(
    resource: "tutorial",
    type: "mov",
    autoPlayWhenReady: true
  )
  @StateObject private var secondController = LoopingVideoController(
    resource: "safari_tutorial",
    type: "mov",
    autoPlayWhenReady: false
  )

  var body: some View {
    NavigationView {
      ZStack {
        // Background
        Color.appBackground.ignoresSafeArea()

        TabView(selection: $currentPage) {
          // First Page - tutorial.mov
          tutorialPageView(
            title: "Welcome to Disco!",
            player: firstController.player,
            isReady: firstController.isReady
          )
          .tag(0)

          // Second Page - safari_tutorial.mov
          tutorialPageView(
            title: "Use Disco in Safari!",
            player: secondController.player,
            isReady: secondController.isReady
          )
          .tag(1)

          // Third Page - static image
          tutorialPageView(
            title: "You're All Set!",
            player: nil,
            isReady: true,
            imageName: "TutorialDisclaimer"
          )
          .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.5), value: currentPage)
        .overlay(alignment: .bottom) {
          VStack(spacing: 12) {
            // Page indicator dots
            HStack(spacing: 8) {
              ForEach(0..<3) { index in
                Circle()
                  .frame(width: 8, height: 8)
                  .foregroundColor(currentPage == index ? .appAccent : .black.opacity(0.3))
              }
            }
            .animation(.easeInOut(duration: 0.2), value: currentPage)

            // Stationary bottom button
            Button {
              if currentPage < 2 {
                withAnimation(.easeInOut(duration: 0.5)) { currentPage += 1 }
              } else {
                completeAndDismiss()
              }
            } label: {
              ZStack {
                Text("Next")
                  .opacity(currentPage < 2 ? 1.0 : 0.0)
                Text("Start Saving")
                  .opacity(currentPage == 2 ? 1.0 : 0.0)
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
    .onDisappear {
      // Controllers deinit automatically handle cleanup.
      // Handle swipe-to-dismiss: ensure completion flow runs exactly once
      if !didComplete { completeAndDismiss() }
    }
    .onChange(of: currentPage) { newPage in
      handlePageChange(newPage)
    }
    .onChange(of: secondController.isReady) { ready in
      // If second video becomes ready while user is already on page 1, start playback.
      if ready && currentPage == 1 { secondController.playIfReady() }
    }
  }

  @ViewBuilder
  private func tutorialPageView(
    title: String,
    player: AVPlayer?,
    isReady: Bool,
    imageName: String? = nil
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

      // Slight overscan so the video content extends beyond the mask and is clipped cleanly
      let overscan: CGFloat = 0.75
      let contentW = maxWidth + overscan
      let contentH = height + overscan

      VStack(spacing: 16) {
        // Title
        Text(title)
          .font(.custom("Avenir", size: 28))
          .fontWeight(.bold)
          .foregroundColor(.primary)
          .multilineTextAlignment(.center)

        // Video area sized exactly to aspect ratio with slight overscan
        ZStack {
          if let imageName = imageName {
            Image(imageName)
              .resizable()
              .scaledToFill()
              .frame(width: contentW, height: contentH)
              .clipped()
          } else {
            if !isReady {
              ProgressView()
                .frame(width: maxWidth, height: height)
            }
            if let player = player {
              // Make the content slightly larger and clip to the exact rounded target size
              VideoPlayer(player: player)
                .frame(width: contentW, height: contentH)
                .allowsHitTesting(false)
                .opacity(isReady ? 1 : 0)
            }
          }
        }
        .frame(width: maxWidth, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

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

  private func handlePageChange(_ newPage: Int) {
    switch newPage {
    case 0:
      if firstController.isReady { firstController.playIfReady() }
      secondController.pause()
    case 1:
      firstController.pause()
      if secondController.isReady { secondController.playIfReady() }
    case 2:
      firstController.pause()
      secondController.pause()
    default:
      break
    }
  }
}

#Preview {
  TutorialView()
    .environmentObject(AppState())
}
