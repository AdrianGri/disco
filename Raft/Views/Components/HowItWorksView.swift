//
//  HowItWorksView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import SwiftUI

struct HowItWorksView: View {
  private let steps = [
    "Enter a website you want to shop at",
    "Let Disco search for best deals",
    "Never pay full price again!",
  ]

  var body: some View {
    VStack(alignment: .leading) {
      Text("How it Works:")
        .fontWeight(.semibold)
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, alignment: .leading)

      ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
        HStack {
          Text("\(index + 1)")
            .fontWeight(.bold)
            .padding(15)
            .background(.appPrimary)
            .clipShape(Circle())
            .foregroundColor(.appAccent)
          Text(step)
        }
      }
    }
  }
}

#Preview {
  HowItWorksView()
}
