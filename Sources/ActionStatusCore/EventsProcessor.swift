// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Octoid

struct EventsProcessor: Processor {
    func query(for session: Session) -> Query {
        return session.eventsQuery
    }
    
    func process(state: ResponseState, response events: Events, in session: Session) -> Bool {
        if let session = session as? RepoSession {
            var latest = session.lastEvent
            var wasPushed = false
            for event in events {
                if event.created_at > session.lastEvent {
                    sessionChannel.log("Found new event: \(event.type) \(event.id) \(event.created_at)")
                    if event.type == "PushEvent" {
                        wasPushed = true
                    }
                    latest = max(latest, event.created_at)
                }
            }
            
            if wasPushed {
                session.schedule(processor: WorkflowRunsProcessor(), for: DispatchTime.now())
            }
            
            session.lastEvent = latest
        }

        return true // always repeat
    }
    
    typealias Payload = Events
}
