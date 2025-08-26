//
//  DiscountCodeService.swift
//  Disco
//
//  Created by Adrian Gri on 2025-08-21.
//

import Foundation

struct PromptRequest: Codable {
    let prompt: String
}

struct CodeInfo: Codable, Identifiable {
    let id = UUID()
    let code: String
    let description: String
    let conditions: String
    let has_description: Bool
    let has_conditions: Bool
}

struct DetailedCodesResponse: Codable {
    let codes: [CodeInfo]
}

class DiscountCodeService {
    static let shared = DiscountCodeService()
    
    private let baseURL = "https://disco-backend.vercel.app/codes-detailed"
    
    private init() {}
    
    func fetchDiscountCodes(for domain: String) async throws -> [CodeInfo] {
        let prompt = "Find current discount codes for \(domain)"
        
        guard let url = URL(string: baseURL) else {
            throw ServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = PromptRequest(prompt: prompt)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ServiceError.invalidResponse
        }
        
        let decodedResponse = try JSONDecoder().decode(DetailedCodesResponse.self, from: data)
        return decodedResponse.codes
    }
}

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
