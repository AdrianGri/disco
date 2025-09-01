//
//  CodeRowView.swift
//  Disco
//
//  Created by Adrian Gri on 2025-08-21.
//

import SwiftUI

struct CodeRowView: View {
  let codeInfo: CodeInfo
  let onCopyCode: (String) -> Void

  var body: some View {
    Button(action: {
      onCopyCode(codeInfo.code)
    }) {
      VStack(alignment: .leading, spacing: 12) {
        // Code and Copy Button Row
        HStack {
          Text(codeInfo.code)
            .font(.custom("Avenir", size: 24))
            .fontWeight(.heavy)
            .foregroundColor(.black)

          Spacer()

          HStack(spacing: 6) {
            Image(systemName: "doc.on.doc")
              .font(.system(size: 14))
            Text("Copy Code")
              .font(.custom("Avenir", size: 14))
              .fontWeight(.medium)
          }
          .foregroundColor(.black)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(Color.black.opacity(0.1))
          .cornerRadius(8)
        }

        // Description
        if codeInfo.has_description {
          Text(codeInfo.description)
            .font(.custom("Avenir", size: 16))
            .fontWeight(.medium)
            .foregroundColor(.black)
        } else {
          Text("Use this code to save money on your order")
            .font(.custom("Avenir", size: 16))
            .fontWeight(.medium)
            .foregroundColor(.black)
        }

        if codeInfo.has_conditions {
          Text(codeInfo.conditions)
            .font(.custom("Avenir", size: 14))
            .foregroundColor(.black.opacity(0.7))

        }
      }
      .padding(20)
      .background(Color(red: 0.7, green: 0.85, blue: 0.9))
      .cornerRadius(16)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
