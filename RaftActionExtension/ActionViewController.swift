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
  let onClose: () -> Void
  let errorMessage: String?
  let detectedDomain: String?

  var body: some View {
    VStack(spacing: 20) {
      HStack {
        Spacer()
        Button(action: onClose) {
          Image(systemName: "xmark")
            .font(.title2)
            .foregroundColor(.gray)
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .clipShape(Circle())
        }
      }
      .padding(.top, 20)
      .padding(.trailing, 20)

      Spacer()

      Image("LogoTransparent")
        .resizable()
        .renderingMode(.original)
        .interpolation(.high)
        .aspectRatio(contentMode: .fit)
        .frame(width: 150, height: 150)

      if let errorMessage = errorMessage {
        Text(errorMessage)
          .font(.custom("Avenir", size: 32))
          .fontWeight(.bold)
        
        Text("Please share a website URL or text containing a link.")
          .multilineTextAlignment(.center)
      } else {
        Text("Start saving money!")
          .font(.custom("Avenir", size: 32))
          .fontWeight(.bold)

        VStack(spacing: 10) {
          if let domain = detectedDomain {
            Text("Tap **below** to open Disco and find discounts for **\(domain)**")
              .multilineTextAlignment(.center)
          } else {
            Text("Tap **below** to open Disco and find discounts for this website")
              .multilineTextAlignment(.center)
          }

          Button(action: onOpenApp) {
            Text("Open Disco")
              .font(.custom("Avenir", size: 18))
              .fontWeight(.bold)
              .foregroundColor(.appAccent)
              .padding()
              .background(.appPrimary)
              .cornerRadius(10)
          }
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
  var hostingController: UIHostingController<ActionExtensionView>?
  var detectedDomain: String?

  override func viewDidLoad() {
    super.viewDidLoad()

    storedExtensionContext = extensionContext
    processExtensionContext()
    setupSwiftUIView(errorMessage: nil, detectedDomain: nil)
  }

  private func processExtensionContext() {
    guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }

    for attachment in extensionItem.attachments ?? [] {
      // Try to get URL first (direct URL shares)
      if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
        attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (data, error) in
          if let url = data as? URL {
            print("✅ Got URL: \(url)")
            self.queryDiscountCodes(for: url)
          } else {
            print("❌ Could not extract URL from attachment")
          }
        }
        return
      }
      
      // Try to get web page (Safari shares)
      if attachment.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
        attachment.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { (data, error) in
          if let dictionary = data as? [String: Any],
             let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any],
             let urlString = results["URL"] as? String,
             let url = URL(string: urlString) {
            print("✅ Got web page URL: \(url)")
            self.queryDiscountCodes(for: url)
          } else {
            print("❌ Could not extract web page URL")
          }
        }
        return
      }
      
      // Try to get plain text
      if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
        attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (data, error) in
          if let text = data as? String {
            print("✅ Got text: \(text)")
            self.handleText(text)
          } else {
            print("❌ Could not extract text from attachment")
          }
        }
        return
      }
    }
  }
  
  private func handleText(_ text: String) {
    // Try to extract a URL from the text
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
    
    if let match = matches?.first, let url = match.url {
      print("🔗 Found URL in text: \(url)")
      queryDiscountCodes(for: url)
    } else {
      print("📝 Plain text with no URL detected")
      // Update the view to show error message
      DispatchQueue.main.async {
        self.setupSwiftUIView(errorMessage: "No Link Found", detectedDomain: nil)
      }
    }
  }

  private func setupSwiftUIView(errorMessage: String?, detectedDomain: String?) {
    let swiftUIView = ActionExtensionView(
      onOpenApp: openDiscoApp,
      onClose: dismissExtension,
      errorMessage: errorMessage,
      detectedDomain: detectedDomain
    )
    
    if let hostingController = hostingController {
      // Update existing view
      hostingController.rootView = swiftUIView
    } else {
      // Create new hosting controller
      let hostingController = UIHostingController(rootView: swiftUIView)
      self.hostingController = hostingController

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
  }

  private func dismissExtension() {
    storedExtensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }

  private func queryDiscountCodes(for url: URL) {
    print("🔍 Preparing to open app for \(url)")
    let domain = url.host ?? "unknown"
    
    detectedDomain = domain

    if let defaults = UserDefaults(suiteName: "com.adriangri.disco") {
      defaults.removeObject(forKey: "discountCodes")
      defaults.set(domain, forKey: "lastQueriedDomain")
    }
    
    // Update the view to show the detected domain
    DispatchQueue.main.async {
      self.setupSwiftUIView(errorMessage: nil, detectedDomain: domain)
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
