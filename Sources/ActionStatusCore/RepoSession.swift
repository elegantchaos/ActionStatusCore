// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/04/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CollectionExtensions
import Foundation
import Logger
import Octoid

public class RepoSession: Session {
    var lastEvent: Date = Date(timeIntervalSinceReferenceDate: 0)

    public init(repo: Repo, context: Octoid.Context) {
        super.init(repo: Target(name: repo.name, owner: repo.owner, workflow: repo.workflow), context: context)
    }
    
    public func requestEvents() {
        schedule(processor: EventsProcessor(), for: DispatchTime.now(), repeatingEvery: defaultInterval)
    }
}
