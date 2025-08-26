//
//  ActionViewController.swift
//  RaftActionExtension
//
//  Created by Adrian Gri on 2025-07-19.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    var storedExtensionContext: NSExtensionContext?

    override func viewDidLoad() {
        super.viewDidLoad()

        storedExtensionContext = extensionContext
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

        view.backgroundColor = UIColor.systemBackground

        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let title = UILabel()
        title.text = "Raft Discount Finder"
        title.font = .boldSystemFont(ofSize: 20)
        title.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)

        let subtitle = UILabel()
        subtitle.text = "Tap below to open Raft and fetch codes"
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .secondaryLabel
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subtitle)

        let button = UIButton(type: .system)
        button.setTitle("Open Raft", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.addTarget(self, action: #selector(self.openRaftApp), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(button)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 300),

            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            title.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            subtitle.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            button.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 16),
            button.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
    }

    func queryDiscountCodes(for url: URL) {
        print("🔍 Preparing to open app for \(url)")
        let domain = url.host ?? "unknown"

        if let defaults = UserDefaults(suiteName: "com.adriangri.disco") {
            defaults.removeObject(forKey: "discountCodes")
            defaults.set(domain, forKey: "lastQueriedDomain")
        }
    }

    @objc func openRaftApp() {
        guard let domain = UserDefaults(suiteName: "com.adriangri.disco")?.string(forKey: "lastQueriedDomain"),
              let deep = URL(string: "raft://showcodes?domain=\(domain)") else {
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
