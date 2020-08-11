// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/08/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

public enum DisplaySize: Int, CaseIterable {
    case automatic = 0
    case small = 1
    case medium = 2
    case large = 3
    case huge = 4
    
    var font: Font {
        switch self {
            case .automatic: return normalised.font
            case .large: return .title
            case .huge: return .largeTitle
            case .medium: return .headline
            case .small: return .body
        }
    }
    
    var normalised: DisplaySize {
        return self == .automatic ? .large : self
    }
    
    var label: String {
        switch self {
            case .automatic: return "Default (\(normalised.label))"
            case .large: return "Large"
            case .huge: return "Huge"
            case .medium: return "Medium"
            case .small: return "Small"
        }
    }
    
    var rowHeight: CGFloat { return 0 }
}

