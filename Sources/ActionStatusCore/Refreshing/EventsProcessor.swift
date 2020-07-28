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
    
    let name = "events"
    let codes = [200, 304]
    
    var processors: [ProcessorBase] { return [self] }
    
    func process(_ events: Events, response: HTTPURLResponse, in session: RepoPollingSession) -> RepeatStatus {
        var wasPushed = false
        var latestEvent = session.lastEvent
        for event in events {
            let date = event.created_at
            if date > session.lastEvent {
                if event.type == "PushEvent" {
                    networkingChannel.log("Found new event: \(event.type) \(event.id) \(date)")
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
