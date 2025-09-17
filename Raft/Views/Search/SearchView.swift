//
//  SearchView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import SwiftUI

struct SearchView: View {
  @EnvironmentObject var appState: AppState
  @Binding var manualDomain: String
  @State private var isKeyboardVisible = false
  @State private var keyboardHeight: CGFloat = 0
  let onUpgradePressed: () -> Void

  var body: some View {
    ZStack {
      Color.appBackground
        .ignoresSafeArea(.all)

      ScrollView {
        VStack(spacing: 20) {
          if isKeyboardVisible {
            Spacer()
          }

          SearchHeaderView(
            isKeyboardVisible: isKeyboardVisible,
            onUpgradePressed: onUpgradePressed,
            purchaseManager: appState.purchaseManager
          )

          SearchInputView(manualDomain: $manualDomain) {
            performSearch()
          }

          SearchButtonView {
            performSearch()
          }

          TryButtonsView { domain in
            appState.setDomainFromDeepLink(domain)
            UIApplication.shared.sendAction(
              #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
          }

          if !isKeyboardVisible {
            Spacer()

            HowItWorksView()
          } else {
            Spacer()
          }
        }
        .padding(.horizontal)
        .frame(
          minHeight: isKeyboardVisible
            ? UIScreen.main.bounds.height - keyboardHeight - 44 : UIScreen.main.bounds.height - 100
        )
        .contentShape(Rectangle())
        .onTapGesture {
          UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .gesture(
          isKeyboardVisible
            ? DragGesture()
              .onEnded { value in
                // Detect swipe down gesture (positive translation.height and sufficient distance)
                if value.translation.height > 50
                  && abs(value.translation.width) < abs(value.translation.height)
                {
                  UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
              } : nil
        )
      }
      .scrollDisabled(isKeyboardVisible)
    }
    .onAppear {
      setupKeyboardObservers()
    }
    .onDisappear {
      removeKeyboardObservers()
    }
    .animation(.bouncy(duration: 0.4), value: isKeyboardVisible)
  }

  private func performSearch() {
    // Dismiss keyboard first
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    let trimmedDomain = manualDomain.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedDomain.isEmpty {
      appState.setDomainFromDeepLink(trimmedDomain)
    }
  }

  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillShowNotification,
      object: nil,
      queue: .main
    ) { notification in
      isKeyboardVisible = true
      if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        as? CGRect
      {
        keyboardHeight = keyboardFrame.height
      }
    }

    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main
    ) { _ in
      isKeyboardVisible = false
      keyboardHeight = 0
    }
  }

  private func removeKeyboardObservers() {
    NotificationCenter.default.removeObserver(
      self, name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.removeObserver(
      self, name: UIResponder.keyboardWillHideNotification, object: nil)
  }
}

#Preview {
  SearchView(manualDomain: .constant(""), onUpgradePressed: {})
    .environmentObject(AppState())
}
