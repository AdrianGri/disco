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
    VStack(alignment: .leading) {
      VStack(alignment: .leading, spacing: 6) {
        Text(codeInfo.code)
          .font(.title2)
          .bold()
          .foregroundColor(.appAccent)

        if codeInfo.has_description {
          Text(codeInfo.description)
            .foregroundColor(.appAccent)
        } else {
          Text("Discount amount unknown")
            .foregroundColor(.appPrimary)
            .italic()
        }

        if codeInfo.has_conditions {
          Text(codeInfo.conditions)
            .font(.caption)
            .foregroundColor(.appPrimary)
        } else {
          Text("Conditions not available")
            .font(.caption)
            .foregroundColor(.appPrimary)
            .italic()
        }
      }
      .padding(.vertical, 6)

      HStack {
        Spacer()
        Button("Copy Code") {
          onCopyCode(codeInfo.code)
        }
        .font(.caption)
        .foregroundColor(.appAccent)
      }
    }
    .padding(.vertical, 4)
  }
}
