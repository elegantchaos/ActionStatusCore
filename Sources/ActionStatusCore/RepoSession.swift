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
    
    public func requestEvents(for deadline: DispatchTime = DispatchTime.now(), tag: String? = nil) {
        networkingChannel.log("scheduling request for \(fullName) deadline: \(deadline)")
        DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
            self.sendRequest(query: self.eventsQuery, tag: tag, repeating: true, completionHandler: self.processEvents)
        }
    }
    
    public func requestWorkflow(for deadline: DispatchTime = DispatchTime.now(), tag: String? = nil) {
        networkingChannel.log("scheduling workflow request for \(fullName)")
        DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
            self.sendRequest(query: self.workflowQuery, tag: tag, repeating: false, completionHandler: self.processWorkflow)
        }
    }
    
    
    enum ResponseState {
        case updated
        case unchanged
        case other
    }
    
    typealias Handler = (ResponseState, Data) throws -> Bool
    
    func sendRequest(query: String, tag: String? = nil, repeating: Bool, completionHandler: @escaping Handler ) {
        let authorization = "bearer \(context.token)"
        var request = URLRequest(url: context.endpoint.appendingPathComponent(query))
        request.addValue(authorization, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        if let tag = tag {
            request.addValue(tag, forHTTPHeaderField: "If-None-Match")
        }
        
        var updatedTag = tag
        var shouldRepeat = repeating
        var repeatInterval = DispatchTimeInterval.seconds(60)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            networkingChannel.log("got response for \(self.fullName)")
            if let error = error {
                networkingChannel.log(error)
            }
            
            var state: ResponseState
            if let response = response as? HTTPURLResponse,
                let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
                let tag = response.value(forHTTPHeaderField: "Etag"),
                let data = data {
                networkingChannel.log("rate limit remaining: \(remaining)")
                if let seconds = response.value(forHTTPHeaderField: "X-Poll-Interval").asInt {
                    repeatInterval = DispatchTimeInterval.seconds(seconds)
                }
                
                switch response.statusCode {
                    case 200:
                        networkingChannel.log("got updates")
                        state = .updated
                    
                    case 304:
                        networkingChannel.log("no changes")
                        state = .unchanged
                    
                    default:
                        networkingChannel.log("Unexpected response: \(response)")
                        state = .other
                }
                
                updatedTag = tag
                if state != .other {
                    do {
                        shouldRepeat = try shouldRepeat && completionHandler(state, data)
                    } catch {
                        networkingChannel.log("Error thrown processing data \(error)")
                    }
                }
            } else {
                print("Couldn't decode response")
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            }
            
            if shouldRepeat {
                DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now().advanced(by: repeatInterval)) {
                    self.sendRequest(query: query, tag: updatedTag, repeating: repeating, completionHandler: completionHandler)
                }
            }
        }
        
        networkingChannel.log("sent request for \(fullName)")
        task.resume()
    }
    
    func processEvents(state: ResponseState, data: Data) throws -> Bool {
        if let parsed = try? JSONSerialization.jsonObject(with: data, options: []), let events = parsed as? [JSONDictionary] {
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
                requestWorkflow()
            }
            
            lastEvent = latestEvent
        }
        
        return true // always repeat
    }
    
    func processWorkflow(state: ResponseState, data: Data) throws -> Bool {
        let decoder = JSONDecoder()
        let run = try decoder.decode(WorkflowRuns.self, from: data).latestRun
        print("Run status was: \(run.status)")
        if run.status == "completed" {
            print("Conclusion was: \(run.conclusion ?? "")")
            return false
        } else {
            return true
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

extension Optional where Wrapped == String {
    var asInt: Int? {
        if let value = self {
            return Int(value)
        } else {
            return nil
        }
    }
}
