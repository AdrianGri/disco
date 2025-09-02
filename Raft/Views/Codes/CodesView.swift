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

  @State private var isAnimating = false
  @State private var slideInOffset: CGFloat = UIScreen.main.bounds.width

  private func startStaggeredAnimations() {
    isAnimating = false

    // Small delay to ensure reset, then trigger animations
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
        isAnimating = true
      }
    }
  }

  private func startSlideInAnimation() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      slideInOffset = 0
    }
  }

  private func startSlideOutAnimation() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      slideInOffset = UIScreen.main.bounds.width
    }

    // Call onClose after animation completes
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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

        Button(action: startSlideOutAnimation) {
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
      .padding(.bottom, 30)

      if viewModel.isLoading || viewModel.codes.isEmpty {
        Spacer()
        VStack {
          SimpleLoadingVideoView(videoName: "loading_animation")
          Text("Loading codes...")
            .font(.custom("Avenir", size: 16))
            .foregroundColor(.gray)
            .padding(.top, 16)
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
          .foregroundColor(.appPrimary)
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
    .offset(x: slideInOffset)
    .onAppear {
      startSlideInAnimation()
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
