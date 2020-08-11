// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Bundles
import SwiftUI

struct PreviewHost: ApplicationHost {
    let info = BundleInfo(for: Bundle.main)
}

public extension String {
    static let defaultOwnerKey = "DefaultOwner"
    static let refreshIntervalKey = "RefreshInterval"
    static let displaySizeKey = "TextSize"
    static let showInMenuKey = "ShowInMenu"
    static let showInDockKey = "ShowInDock"
}

public class ViewState: ObservableObject {

    @Published public var isEditing: Bool = false
    @Published public var selectedID: UUID? = nil
    @Published public var displaySize: DisplaySize = .automatic
    @Published public var refreshRate: RefreshRate = .automatic
    
    public let host: ApplicationHost
    public let padding: CGFloat = 10
    let editIcon = "info.circle"
    let startEditingIcon = "lock.fill"
    let stopEditingIcon = "lock.open.fill"
    let preferencesIcon = "gearshape"
    
    let formHeaderFont = Font.headline
    
    public init(host: ApplicationHost) {
        self.host = host
    }
    
    @discardableResult func addRepo(to model: Model) -> Repo {
        let newRepo = model.addRepo(viewState: self)
        host.saveState()
        selectedID = newRepo.id
        return newRepo
    }
}
