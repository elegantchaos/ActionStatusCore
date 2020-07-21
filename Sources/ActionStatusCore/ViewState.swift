// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Bundles
import SwiftUI

struct PreviewHost: ApplicationHost {
    let info = BundleInfo(for: Bundle.main)
    func saveState() {
        
    }
    
    func stateWasEdited() {
        
    }
    
    func save(output: Generator.Output) {
        
    }
    
    func openGithub(with repo: Repo, at location: Repo.GithubLocation) {
        
    }
}

protocol ApplicationHost {
    var info: BundleInfo { get }
    func saveState()
    func stateWasEdited()
    func save(output: Generator.Output)
    func openGithub(with repo: Repo, at location: Repo.GithubLocation)
}

class ViewState: ObservableObject {
    enum TextSize: Int {
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
    
    @Published var isEditing: Bool = false
    @Published var selectedID: UUID? = nil
    @Published var repoTextSize: TextSize = .automatic

    let host: ApplicationHost
    let padding: CGFloat = 10
    let editIcon = "info.circle"
    let startEditingIcon = "lock.fill"
    let stopEditingIcon = "lock.open.fill"
    
    let formHeaderFont = Font.headline
    
    init(host: ApplicationHost) {
        self.host = host
    }
    
    @discardableResult func addRepo(to model: Model) -> Repo {
        let newRepo = model.addRepo()
        saveState()
        selectedID = newRepo.id
        return newRepo
    }
    
    func saveState() {
        host.saveState()
    }
}
