//
//  SearchInputView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import SwiftUI

struct SearchInputView: View {
  @Binding var manualDomain: String
  @FocusState private var isTextFieldFocused: Bool
  let onSearch: () -> Void

  var body: some View {
    VStack {
      Text("Paste or type a website **below** to find discounts")
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, alignment: .center)
        .onTapGesture {
          // If text field is already focused, dismiss keyboard
          if isTextFieldFocused {
            isTextFieldFocused = false
          } else {
            isTextFieldFocused = true
          }
        }

      TextField("e.g. amazon.com", text: $manualDomain)
        .textFieldStyle(PlainTextFieldStyle())
        .focused($isTextFieldFocused)
        .padding()
        .frame(maxWidth: .infinity)
        .background(.grayBackground)
        .clipShape(Capsule())
        .autocapitalization(.none)
        .contentShape(Rectangle())
        .autocorrectionDisabled(true)
    }
  }
}

#Preview {
  SearchInputView(manualDomain: .constant("")) {
    print("Search triggered")
  }
}
