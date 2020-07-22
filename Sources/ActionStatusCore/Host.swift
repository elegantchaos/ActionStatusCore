// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/07/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Bundles

public protocol ApplicationHost {
    var info: BundleInfo { get }
    func saveState()
    func stateWasEdited()
    func save(output: Generator.Output)
    func openGithub(with repo: Repo, at location: Repo.GithubLocation)
    func pauseRefresh()
    func resumeRefresh()
}

extension ApplicationHost {
    var info: BundleInfo {
        BundleInfo(for: Bundle.main)
    }
    
    func saveState() {
        
    }
    
    func stateWasEdited() {
        
    }
    
    func save(output: Generator.Output) {
        
    }
    
    func openGithub(with repo: Repo, at location: Repo.GithubLocation) {
        
    }

    func pauseRefresh() {
        
    }
    func resumeRefresh() {
        
    }

}
