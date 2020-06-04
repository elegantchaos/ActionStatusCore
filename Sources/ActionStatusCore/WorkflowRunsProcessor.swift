// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Octoid

struct WorkflowRunsProcessor: Processor {
    typealias Payload = WorkflowRuns
    func query(for session: Session) -> Query {
        return session.workflowQuery
    }
    
    func process(state: ResponseState, response runs: Payload, in session: Session) -> Bool {
        let run = runs.latestRun
        print("Run status for \(session.target) is: \(run.status)")
        if run.status == "completed" {
            print("Conclusion for \(session.target) was: \(run.conclusion ?? "")")
            return false
        } else {
            return true
        }
    }
}
