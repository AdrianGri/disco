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
      Text("Paste or type a website **below** and let Disco find you discounts")
        .font(.custom("Avenir", size: 12))
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, alignment: .center)
      
      TextField("e.g. amazon.com", text: $manualDomain)
        .textFieldStyle(PlainTextFieldStyle())
        .focused($isTextFieldFocused)
        .padding()
        .frame(maxWidth: .infinity)
        .background(.textFieldBackground)
        .clipShape(Capsule())
        .autocapitalization(.none)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    .onTapGesture {
      isTextFieldFocused = true
    }
  }
}

#Preview {
  SearchInputView(manualDomain: .constant("")) {
    print("Search triggered")
  }
}
