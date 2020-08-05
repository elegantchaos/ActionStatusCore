// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/04/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CollectionExtensions
import Foundation
import Logger
import Octoid
import JSONSession



public class RepoPollingSession: Octoid.Session {
    let repo: Repo // TODO: add a SessionSession (need a better name) to Session and pass that to Processors instead of the Session
    let workflowProcessor = WorkflowRunsProcessor()
    let eventsProcessor = EventsProcessor()
    let refreshController: OctoidRefreshController
    var lastEvent: Date
    
    public var fullName: String { return "\(repo.owner)/\(repo.name)" }
    var tagKey: String { return "\(fullName)-tag" }
    var lastEventKey: String { return "\(fullName)-lastEvent" }
    
    public init(controller: OctoidRefreshController, repo: Repo, token: String) {
        self.refreshController = controller
        self.repo = repo
        self.lastEvent = Date(timeIntervalSinceReferenceDate: 0)
        super.init(token: token)
        load()
    }
    
    func load() {
        let seconds = UserDefaults.standard.double(forKey: lastEventKey)
        if seconds != 0 {
            lastEvent = Date(timeIntervalSinceReferenceDate: seconds)
        }
    }
    
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(lastEvent.timeIntervalSinceReferenceDate, forKey: lastEventKey)
    }
    
    public func scheduleEvents() {
        networkingChannel.log("scheduling request for \(fullName)")
        let resource = EventsResource(name: repo.name, owner: repo.owner)
        poll(target: resource, processors: eventsProcessor, repeatingEvery: 30.0)
    }
    
    public func scheduleWorkflow() {
        networkingChannel.log("scheduling workflow request for \(fullName)")
        let resource = WorkflowResource(name: repo.name, owner: repo.owner, workflow: repo.workflow)
        poll(target: resource, processors: workflowProcessor, repeatingEvery: 30.0)
    }
}
