//
//  TryButtonsView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import SwiftUI

struct TryButtonsView: View {
  @Binding var manualDomain: String
  let onDomainSelect: (String) -> Void

  private let domains = ["nike.com", "sephora.com", "zara.com"]

  var body: some View {
    HStack {
      Text("Try:")
        .foregroundColor(.gray)

      ForEach(domains, id: \.self) { domain in
        Button(domain) {
          manualDomain = domain
          onDomainSelect(domain)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(.textFieldBackground)
        .clipShape(Capsule())
        .foregroundColor(.black)
      }
    }
    .font(.custom("Avenir", size: 14))
  }
}

#Preview {
  TryButtonsView(manualDomain: .constant("")) { domain in
    print("Selected domain: \(domain)")
  }
}
