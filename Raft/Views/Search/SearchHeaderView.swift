//
//  SearchHeaderView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import SwiftUI

struct SearchHeaderView: View {
  let isKeyboardVisible: Bool

  var body: some View {
    VStack(spacing: 20) {
      if !isKeyboardVisible {
        Image("LogoTransparent")
          .resizable()
          .renderingMode(.original)
          .interpolation(.high)
          .aspectRatio(contentMode: .fit)
          .frame(width: 150, height: 150)
          .transition(.opacity)
          .padding(.top, 20)
          .padding(.bottom, 10)
      }

      Text("Start saving money\nat your favorite stores!")
        .font(.custom("Avenir", size: 32))
        .fontWeight(.heavy)
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .allowsHitTesting(false)
    }
  }
}

#Preview {
  SearchHeaderView(isKeyboardVisible: false)
}
