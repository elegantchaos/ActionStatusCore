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
    
    override public init(model: Model) {
        self.sessions = []
        super.init(model: model)
    }

    override func startRefresh() {
        do {
            let token = try Keychain.default.getToken(user: user, server: server)
            var sessions: [RepoPollingSession] = []
            for repo in model.items.values {
                let session = RepoPollingSession(controller: self, repo: repo, token: token)
                session.scheduleEvents()
                sessions.append(session)
            }
        } catch {
            refreshChannel.log("Failed to start refresh: \(error)")
        }
    }
    
    override func cancelRefresh() {
        
    }
    
    func update(repo: Repo, with run: WorkflowRun) {
        print("Latest status for \(repo.name) was: \(run.status)")
        print("Conclusion was: \(run.conclusion ?? "")")
        model.update(repo: repo)
    }
}
