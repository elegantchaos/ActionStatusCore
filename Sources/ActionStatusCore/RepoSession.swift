// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/04/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CollectionExtensions
import Foundation
import Logger


public let networkingChannel = Channel("Networking")

public struct Context {
    public let endpoint: URL
    public let token: String
    
    public init(endpoint: URL, token: String) {
        self.endpoint = endpoint
        self.token = token
    }
}

public class RepoSession {
    let repo: Repo
    let context: Context
    var lastEvent: Date
    
    public var fullName: String { return "\(repo.owner)/\(repo.name)" }
    var tagKey: String { return "\(fullName)-tag" }
    var lastEventKey: String { return "\(fullName)-lastEvent" }
    
    var eventsQuery: String { return  "repos/\(repo.owner)/\(repo.name)/events" }
    var workflowQuery: String { return  "repos/\(repo.owner)/\(repo.name)/actions/workflows/Tests.yml/runs" }
    
    public init(repo: Repo, context: Context) {
        self.repo = repo
        self.context = context
        self.lastEvent = Date(timeIntervalSinceReferenceDate: 0)
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
        DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
            self.sendRequest(query: self.eventsQuery, tag: tag) { data, response, error in
                self.handle(response: response, data: data, error: error)
            }
        }
    }
    
    public func scheduleWorkflow(for deadline: DispatchTime = DispatchTime.now(), tag: String? = nil) {
        networkingChannel.log("scheduling workflow request for \(fullName)")
        DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
            self.sendRequest(query: self.workflowQuery, tag: tag) { data, response, error in
                self.handleWorkflow(data: data, response: response, error: error)
            }
        }
    }
    
    func process(response: HTTPURLResponse, events: [JSONDictionary]) {
        guard
            let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
            let tag = response.value(forHTTPHeaderField: "Etag"),
            let interval = response.value(forHTTPHeaderField: "X-Poll-Interval"), let seconds = Int(interval) else {
                schedule(for: DispatchTime.now().advanced(by: .seconds(60)))
                return
        }
        
        networkingChannel.log("rate limit remaining: \(remaining)")
        
        var latestEvent = lastEvent
        var wasPushed = false
        for event in events {
            if let type = event[stringWithKey: "type"], let id = event[stringWithKey: "id"], let date = event[dateWithKey: "created_at"] {
                if date > lastEvent {
                    networkingChannel.log("Found new event: \(type) \(id) \(date)")
                    if type == "PushEvent" {
                        wasPushed = true
                    }
                    latestEvent = max(latestEvent, date)
                }
            }
        }
        
        if wasPushed {
            scheduleWorkflow()
        }
        
        lastEvent = latestEvent
        schedule(for: DispatchTime.now().advanced(by: .seconds(seconds)), tag: tag)
    }
    
    func sendRequest(query: String, tag: String? = nil, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let authorization = "bearer \(context.token)"
        var request = URLRequest(url: context.endpoint.appendingPathComponent(query))
        request.addValue(authorization, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        if let tag = tag {
            request.addValue(tag, forHTTPHeaderField: "If-None-Match")
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            networkingChannel.log("got response for \(self.fullName)")
            completionHandler(data, response, error)
        }
        
        networkingChannel.log("sent request for \(fullName)")
        task.resume()
    }
    
    func handle(response: URLResponse?, data: Data?, error: Error?) {
        networkingChannel.log("handled")
        if let error = error {
            networkingChannel.log(error)
        }
        
        if let response = response as? HTTPURLResponse, let data = data, let parsed = try? JSONSerialization.jsonObject(with: data, options: []), let events = parsed as? [JSONDictionary] {
            switch response.statusCode {
                case 200:
                    networkingChannel.log("got events")
                    process(response: response, events: events)
                
                case 304:
                    networkingChannel.log("no changes")
                    process(response: response, events: events)
                
                default:
                    print("Unexpected response: \(response)")
            }
            
        } else {
            print("Couldn't decode response")
            if let data = data, let string = String(data: data, encoding: .utf8) {
                print(string)
            }
        }
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
