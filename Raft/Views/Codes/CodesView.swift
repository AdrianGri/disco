//
//  CodesView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import AVKit
import SwiftUI

struct CodesView: View {
  let domain: String
  @ObservedObject var viewModel: DiscountCodeViewModel
  let onClose: () -> Void
  @Environment(\.dismiss) private var dismiss

  @State private var isAnimating = false
  @State private var currentLoadingTextIndex = 0
  @State private var loadingTextTimer: Timer?

  private let loadingPhrases = [
    "Finding you the best deals...",
    "Searching for discounts...",
    "Looking for sales...",
  ]

  private func startStaggeredAnimations() {
    isAnimating = false

    // Small delay to ensure reset, then trigger animations
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
        isAnimating = true
      }
    }
  }

  private func startLoadingTextCycle() {
    // Start on a random index
    currentLoadingTextIndex = Int.random(in: 0..<loadingPhrases.count)

    // Start cycling every 5 seconds
    loadingTextTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
      withAnimation(.easeInOut(duration: 0.3)) {
        currentLoadingTextIndex = (currentLoadingTextIndex + 1) % loadingPhrases.count
      }
    }
  }

  private func stopLoadingTextCycle() {
    loadingTextTimer?.invalidate()
    loadingTextTimer = nil
  }

  private func handleClose() {
    // First dismiss the navigation
    dismiss()

    // Then clear the state after navigation animation completes
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
      onClose()
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header with close button
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Discount codes for")
            .font(.custom("Avenir", size: 16))
            .fontWeight(.regular)
            .foregroundColor(.black)

          Text(domain)
            .font(.custom("Avenir", size: 24))
            .fontWeight(.semibold)
            .foregroundColor(.black)
        }

        Spacer()

        Button(action: handleClose) {
          Image(systemName: "xmark")
            .font(.title2)
            .foregroundColor(.gray)
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .clipShape(Circle())
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, viewModel.isLoading ? 0 : 30)

      if viewModel.isLoading {
        Spacer()
        VStack {
          LoopingVideoView(videoName: "loading_animation")
          Text(loadingPhrases[currentLoadingTextIndex])
            .font(.custom("Avenir", size: 20))
            .padding(.top, 16)
            .animation(.easeInOut(duration: 0.3), value: currentLoadingTextIndex)
        }
        Spacer()
      } else if let errorMessage = viewModel.errorMessage {
        Spacer()
        VStack {
          Text("Error: \(errorMessage)")
            .foregroundColor(.appAccent)
            .padding()
          Button("Try Again") {
            viewModel.fetchCodes(for: domain)
          }
          .foregroundColor(.white)
          .padding()
        }
        Spacer()
      } else if viewModel.codes.isEmpty {
        Spacer()
        Text("No codes found")
          .font(.custom("Avenir", size: 20))
          .padding()
        Spacer()
      } else {
        ScrollView {
          VStack(spacing: 16) {
            ForEach(Array(viewModel.codes.enumerated()), id: \.element.id) { index, code in
              CodeRowView(codeInfo: code) { codeString in
                viewModel.copyCode(codeString)
              }
              .scaleEffect(isAnimating ? 1.0 : 0.8)
              .opacity(isAnimating ? 1.0 : 0.0)
              .animation(
                .spring(response: 0.5, dampingFraction: 0.7)
                  .delay(Double(index) * 0.05),
                value: isAnimating
              )
            }
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 20)
        }
        .onAppear {
          // Trigger animations when view first appears with codes
          if !viewModel.codes.isEmpty && !isAnimating {
            startStaggeredAnimations()
          }
        }
        .onChange(of: viewModel.codes) { _ in
          // Trigger animations when codes change
          startStaggeredAnimations()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.appBackground)
    .navigationBarHidden(true)
    .onAppear {
      // Trigger animations when view first appears
      if !viewModel.codes.isEmpty && !isAnimating {
        startStaggeredAnimations()
      }

      // Start loading text cycle if currently loading
      if viewModel.isLoading {
        startLoadingTextCycle()
      }
    }
    .onDisappear {
      // Clean up timer when view disappears
      stopLoadingTextCycle()
    }
    .onChange(of: viewModel.isLoading) { isLoading in
      if isLoading {
        startLoadingTextCycle()
      } else {
        stopLoadingTextCycle()
      }
    }
    .overlay(
      VStack {
        Spacer()
        HStack {
          Text("Code copied to clipboard!")
            .font(.custom("Avenir", size: 14))
            .fontWeight(.medium)
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.6))
        .cornerRadius(25)
        .padding(.bottom, 50)
        .opacity(viewModel.showCopyToast ? 1.0 : 0.0)
        .scaleEffect(viewModel.showCopyToast ? 1.0 : 0.8)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showCopyToast)
        .allowsHitTesting(false)
      }
    )
  }
}

#Preview {
  CodesView(domain: "www.amazon.com", viewModel: DiscountCodeViewModel(), onClose: {})
}
