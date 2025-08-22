//
//  AppColors.swift
//  Raft
//
//  Created by Adrian Gri on 2025-08-22.
//

import SwiftUI

// MARK: - Fallback Colors (if Asset Catalog not available)
extension Color {
    /// Blue primary - #71a1b6
    static let fallbackPrimary = Color(red: 0.443, green: 0.631, blue: 0.714)
    
    /// Dark blue accent - #1e3b56  
    static let fallbackAccent = Color(red: 0.118, green: 0.231, blue: 0.337)
    
    /// Beige background - #fbf4e8
    static let fallbackBackground = Color(red: 0.984, green: 0.957, blue: 0.910)
    
    /// White surface color
    static let fallbackSurface = Color.white
}
