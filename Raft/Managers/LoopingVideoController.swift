//
//  LoopingVideoController.swift
//  Disco
//
//  Created by Adrian Gri on 2025-10-07.
//
//  A small reusable helper that encapsulates the logic for:
//  - Loading a bundled video resource into an AVPlayer
//  - Observing readiness to play (exposing a published `isReady` flag)
//  - Looping seamlessly when playback reaches the end
//  - Providing a simple `playIfReady()` hook
//
//  This keeps view code (e.g. TutorialView) lean and avoids duplication.
//

import Foundation
import AVKit
import Combine

final class LoopingVideoController: ObservableObject {
  @Published private(set) var isReady: Bool = false
  @Published private(set) var player: AVPlayer?

  private var statusObserver: NSKeyValueObservation?
  private var playbackObserver: NSObjectProtocol?

  private let resource: String
  private let type: String
  private let autoPlayWhenReady: Bool

  init(resource: String, type: String, autoPlayWhenReady: Bool = false) {
    self.resource = resource
    self.type = type
    self.autoPlayWhenReady = autoPlayWhenReady
    setup()
  }

  deinit {
    teardown()
  }

  func playIfReady() {
    guard isReady else { return }
    player?.play()
  }

  func pause() { player?.pause() }

  private func setup() {
    guard let path = Bundle.main.path(forResource: resource, ofType: type) else {
      print("❌ Could not find \(resource).\(type)")
      return
    }
    let url = URL(fileURLWithPath: path)
    let item = AVPlayerItem(url: url)
    let p = AVPlayer(playerItem: item)
    p.isMuted = true
    p.automaticallyWaitsToMinimizeStalling = false
    self.player = p

    statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] _, _ in
      guard let self = self else { return }
      if item.status == .readyToPlay {
        DispatchQueue.main.async {
          self.isReady = true
          if self.autoPlayWhenReady { self.player?.play() }
        }
      }
    }

    playbackObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak p] _ in
      p?.seek(to: .zero)
      p?.play()
    }
  }

  private func teardown() {
    player?.pause()
    player = nil
    isReady = false
    statusObserver?.invalidate()
    statusObserver = nil
    if let token = playbackObserver { NotificationCenter.default.removeObserver(token) }
    playbackObserver = nil
  }
}
