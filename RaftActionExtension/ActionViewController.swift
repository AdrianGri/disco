//
//  ActionViewController.swift
//  DiscoActionExtension
//
//  Created by Adrian Gri on 2025-07-19.
//

import MobileCoreServices
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - SwiftUI View
struct ActionExtensionView: View {
  let onOpenApp: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      Spacer()
      
      Image("LogoTransparent")
        .resizable()
        .renderingMode(.original)
        .interpolation(.high)
        .aspectRatio(contentMode: .fit)
        .frame(width: 150, height: 150)

        Text("Start saving money!")
          .font(.custom("Avenir", size: 32))
          .fontWeight(.bold)

      
      VStack(spacing: 10) {
        Text("Tap **below** to open Disco and find discounts")
          .font(.custom("Avenir", size: 12))
          .multilineTextAlignment(.center)
        
        Button(action: onOpenApp) {
          Text("Open Disco")
            .font(.custom("Avenir", size: 18))
            .fontWeight(.medium)
            .foregroundColor(.appAccent)
            .padding()
            .background(.appPrimary)
            .cornerRadius(10)
        }
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.appBackground)
  }
}

// MARK: - UIKit Controller
class ActionViewController: UIViewController {

  var storedExtensionContext: NSExtensionContext?

  override func viewDidLoad() {
    super.viewDidLoad()

    storedExtensionContext = extensionContext
    processExtensionContext()
    setupSwiftUIView()
  }

  private func processExtensionContext() {
    guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }

    for attachment in extensionItem.attachments ?? [] {
      if attachment.hasItemConformingToTypeIdentifier("public.url") {
        attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { (data, error) in
          if let url = data as? URL {
            print("✅ Got URL: \(url)")
            self.queryDiscountCodes(for: url)
          } else {
            print("❌ Could not extract URL from attachment")
          }
        }
        break
      }
    }
  }

  private func setupSwiftUIView() {
    let swiftUIView = ActionExtensionView(onOpenApp: openDiscoApp)
    let hostingController = UIHostingController(rootView: swiftUIView)

    addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: self)

    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func queryDiscountCodes(for url: URL) {
    print("🔍 Preparing to open app for \(url)")
    let domain = url.host ?? "unknown"

    if let defaults = UserDefaults(suiteName: "com.adriangri.disco") {
      defaults.removeObject(forKey: "discountCodes")
      defaults.set(domain, forKey: "lastQueriedDomain")
    }
  }

  private func openDiscoApp() {
    guard
      let domain = UserDefaults(suiteName: "com.adriangri.disco")?.string(
        forKey: "lastQueriedDomain"),
      let deep = URL(string: "disco://showcodes?domain=\(domain)")
    else {
      return
    }

    _ = openURL(deep)
    storedExtensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }

  @objc @discardableResult
  private func openURL(_ url: URL) -> Bool {
    var responder: UIResponder? = self
    while let r = responder {
      if let app = r as? UIApplication {
        if #available(iOS 18.0, *) {
          app.open(url, options: [:], completionHandler: nil)
        } else {
          _ = app.perform(#selector(openURL(_:)), with: url)
        }
        return true
      }
      responder = r.next
    }
    return false
  }
}
