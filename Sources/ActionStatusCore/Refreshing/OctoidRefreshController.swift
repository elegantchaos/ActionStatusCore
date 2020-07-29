// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/07/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Keychain
import Octoid

let user = "sam@elegantchaos.com"
let server = "api.github.com"

public class OctoidRefreshController: RefreshController {
    internal var sessions: [RepoPollingSession]
    internal let token: String
    
    public init(model: Model, token: String) {
        self.sessions = []
        self.token = token
        super.init(model: model)
    }

    override func startRefresh() {
        var sessions: [RepoPollingSession] = []
        for repo in model.items.values {
//            if repo.name == "_privateTest" {
                let session = RepoPollingSession(controller: self, repo: repo, token: token)
                session.scheduleWorkflowRepeating()
                sessions.append(session)
//            }
        }
        self.sessions = sessions
    }
    
    override func cancelRefresh() {
        for session in sessions {
//            session
        }
        self.sessions.removeAll()
    }
    
    func update(repo: Repo, with run: WorkflowRun) {
        print("Latest status for \(repo.name) was: \(run.status)")
        print("Conclusion was: \(run.conclusion ?? "")")
        var updated = repo
        if run.conclusion == "failure" {
            updated.state = .failing
        } else if run.conclusion == "success" {
            updated.state = .passing
        }
        
        DispatchQueue.main.async {
            self.model.update(repo: updated)
        }
    }
}
