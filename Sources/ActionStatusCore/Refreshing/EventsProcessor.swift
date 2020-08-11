// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/07/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Octoid
import JSONSession

struct EventsProcessor: Processor {
    typealias SessionType = RepoPollingSession
    typealias Payload = Events
    
    let name = "events list"
    let codes = [200]

    func process(_ events: Events, response: HTTPURLResponse, for request: Request, in session: RepoPollingSession) -> RepeatStatus {
        var wasPushed = false
        var latestEvent = session.lastEvent
        for event in events {
            let date = event.created_at
            if date > session.lastEvent {
                if event.type == "PushEvent" {
                    refreshChannel.log("Found new event: \(event.type) \(event.id) \(date)")
                    wasPushed = true
                }
                latestEvent = max(latestEvent, date)
            }
        }
        
        if wasPushed {
            session.scheduleWorkflow()
        }
        
        session.lastEvent = latestEvent
        return .inherited
    }
}


struct EventsProcessorGroup: ProcessorGroup {
    let name = "events"
    var processors: [ProcessorBase] = [
        EventsProcessor(),
        UnchangedProcessor(),
        MessageProcessor<RepoPollingSession>()
    ]
}
