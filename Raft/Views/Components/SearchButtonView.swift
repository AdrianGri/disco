//
//  SearchButtonView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import SwiftUI

struct SearchButtonView: View {
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: "magnifyingglass")
        Text("Search for Discounts")
      }
      .foregroundColor(.appAccent)
      .padding()
      .frame(maxWidth: 250)
      .background(.appPrimary)
      .cornerRadius(10)
      .fontWeight(.semibold)
    }
    .padding(.horizontal)
  }
}

#Preview {
  SearchButtonView {
    print("Search button tapped")
  }
}
