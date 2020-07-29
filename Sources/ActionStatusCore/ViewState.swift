// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Bundles
import SwiftUI

struct PreviewHost: ApplicationHost {
    let info = BundleInfo(for: Bundle.main)
}

public class ViewState: ObservableObject {
    public enum TextSize: Int {
        case automatic = 0
        case small = 1
        case medium = 2
        case large = 3
        case huge = 4
        
        var font: Font {
            switch self {
                case .automatic, .large: return .title
                case .huge: return .largeTitle
                case .medium: return .headline
                case .small: return .body
            }
        }
        
        var rowHeight: CGFloat { return 0 }
    }
    
    @Published public var isEditing: Bool = false
    @Published public var selectedID: UUID? = nil
    @Published public var repoTextSize: TextSize = .automatic

    public let host: ApplicationHost
    public let padding: CGFloat = 10
    let editIcon = "info.circle"
    let startEditingIcon = "lock.fill"
    let stopEditingIcon = "lock.open.fill"
    
    let formHeaderFont = Font.headline
    
    public init(host: ApplicationHost) {
        self.host = host
    }
    
    @discardableResult func addRepo(to model: Model) -> Repo {
        let newRepo = model.addRepo()
        host.saveState()
        selectedID = newRepo.id
        return newRepo
    }
}
