//
//  Models.swift
//  Disco
//
//  Created by Adrian Gri on 2025-09-01.
//

import Foundation

// MARK: - API Models
struct PromptRequest: Codable {
  let prompt: String
}

struct DetailedCodesResponse: Codable {
  let codes: [CodeInfo]
}

// MARK: - Data Models
struct CodeInfo: Codable, Identifiable, Equatable {
  let id = UUID()
  let code: String
  let description: String
  let conditions: String
  let has_description: Bool
  let has_conditions: Bool
}

// MARK: - Error Models
enum ServiceError: LocalizedError {
  case invalidURL
  case invalidResponse
  case decodingError

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid response from server"
    case .decodingError:
      return "Failed to decode response"
    }
  }
}
