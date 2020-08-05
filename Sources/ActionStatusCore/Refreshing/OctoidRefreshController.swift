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
        let filter: String? = "Coverage"
        for repo in model.items.values {
            if filter == nil || filter == repo.name {
                let session = RepoPollingSession(controller: self, repo: repo, token: token)
                session.scheduleEvents()
                session.scheduleWorkflow()
                sessions.append(session)
            }
        }
        self.sessions = sessions
    }
    
    override func cancelRefresh() {
        for session in sessions {
            session.cancel()
        }
        self.sessions.removeAll()
    }
    
    func update(repo: Repo, message: Message) {
        print("Error for \(repo.name) was: \(message.message)")
        var updated = repo
        updated.state = .unknown
        DispatchQueue.main.async {
            self.model.update(repo: updated)
        }

    }
    
    func update(repo: Repo, with run: WorkflowRun) {
        print("Latest status for \(repo.name) was: \(run.status)")
        print("Conclusion was: \(run.conclusion ?? "")")
        var updated = repo
        switch run.status {
            case "queued":
                updated.state = .queued
            case "in_progress":
                updated.state = .running
            case "completed":
                switch run.conclusion {
                    case "success":
                        updated.state = .passing
                    case "failure":
                        updated.state = .failing
                    default:
                        updated.state = .unknown
                }
            default:
                updated.state = .unknown
        }

        DispatchQueue.main.async {
            self.model.update(repo: updated)
        }
    }
}
