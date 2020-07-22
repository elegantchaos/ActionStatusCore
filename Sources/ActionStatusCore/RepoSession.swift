// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/04/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CollectionExtensions
import Foundation
import Logger
import Octoid
import JSONSession

public let networkingChannel = Channel("Networking")

struct ProcessEvent: Processor {
    typealias SessionType = RepoSession
    
    var processors: [ProcessorBase] { return [self] }
    
    typealias Payload = Events

    let name = "Events"
    let codes = [200, 304]
    
    func process(_ events: Events, response: HTTPURLResponse, in session: RepoSession) -> RepeatStatus {
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
        
            if wasPushed {
                session.scheduleWorkflow()
            }
        
            session.lastEvent = latestEvent
            return .inherited
    }
}

struct WorkflowProcessor: ProcessorGroup {
    let name = "Events"
    let processors: [ProcessorBase] = []
}

    public class RepoSession: Octoid.Session {
    let repo: Repo
        let workflowProcessor = WorkflowProcessor()
        let eventsProcessor = ProcessEvent()
    var lastEvent: Date
    
    public var fullName: String { return "\(repo.owner)/\(repo.name)" }
    var tagKey: String { return "\(fullName)-tag" }
    var lastEventKey: String { return "\(fullName)-lastEvent" }
    
    public init(repo: Repo, token: String) {
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
    
    public func schedule(for deadline: DispatchTime = DispatchTime.now(), tag: String? = nil) {
        networkingChannel.log("scheduling request for \(fullName) deadline: \(deadline)")
        let target = EventsTarget(name: repo.name, owner: repo.owner)
        schedule(target: target, processors: eventsProcessor)
    }
    
    public func scheduleWorkflow(for deadline: DispatchTime = DispatchTime.now(), tag: String? = nil) {
        networkingChannel.log("scheduling workflow request for \(fullName)")
        let processors = WorkflowProcessor()
        let target = WorkflowTarget(name: repo.name, owner: repo.owner, workflow: repo.workflow)
        schedule(target: target, processors: processors, tag: tag)
    }
    
    func handleWorkflow(data: Data?, response: URLResponse?, error: Error?) {
        networkingChannel.log("handled workflow")
        if let error = error {
            networkingChannel.log(error)
        }
        
        let decoder = JSONDecoder()
        if let response = response as? HTTPURLResponse, let data = data {
            do {
                let runs = try decoder.decode(WorkflowRuns.self, from: data)
                switch response.statusCode {
                    case 200:
                        networkingChannel.log("got events")
                        process(response: response, run: runs.latestRun)
                    
                    case 304:
                        networkingChannel.log("no changes")
                        process(response: response, run: runs.latestRun)
                    
                    default:
                        print("Unexpected response: \(response)")
                }
            } catch {
                print("Couldn't decode data: \(error)")
            }
        } else {
            print("Couldn't decode response")
            if let data = data, let string = String(data: data, encoding: .utf8) {
                print(string)
            }
        }
    }
    
    func process(response: HTTPURLResponse, run: WorkflowRun) {
        guard let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"), let tag = response.value(forHTTPHeaderField: "Etag") else {
            print("Bad response: \(response)")
            return
        }
        
        networkingChannel.log("rate limit remaining: \(remaining)")
        
        print("Run status was: \(run.status)")
        if run.conclusion == "completed" {
            print("Conclusion was: \(run.conclusion ?? "")")
        } else {
            scheduleWorkflow(for: DispatchTime.now().advanced(by: .seconds(60)), tag: tag)
        }
    }
}
    
    struct WorkflowRuns: Codable {
        let total_count: Int
        let workflow_runs: [WorkflowRun]
        
        var latestRun: WorkflowRun {
            let sorted = workflow_runs.sorted(by: \WorkflowRun.run_number)
            return sorted[total_count - 1]
        }
    }
    
    struct WorkflowRun: Codable {
        let id: Int
        let run_number: Int
        let status: String
        let conclusion: String?
    }
    
    extension Sequence {
        func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
            return sorted { a, b in
                return a[keyPath: keyPath] < b[keyPath: keyPath]
            }
        }
}
