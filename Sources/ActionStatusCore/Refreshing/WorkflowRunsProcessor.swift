// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/07/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession
import Octoid

struct WorkflowRunsProcessor: Processor {
    typealias SessionType = RepoPollingSession
    typealias Payload = WorkflowRuns
    
    let codes = [200, 304]
    let name = "workflows"
    
    var processors: [ProcessorBase] { return [self] }
    
    func process(_ runs: WorkflowRuns, response: HTTPURLResponse, in session: RepoPollingSession) -> RepeatStatus {
        
        let latest = runs.latestRun
        print("Latest status for \(session.repo.name) was: \(latest.status)")
        if latest.conclusion == "completed" {
            print("Conclusion was: \(latest.conclusion ?? "")")
            return .cancel
        } else {
            return .inherited
        }
    }
}
