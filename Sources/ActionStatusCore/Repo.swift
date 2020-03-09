// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import DictionaryCoding

@dynamicMemberLookup public struct WorkflowSettings: Codable, Equatable {
    public var options: [String] = []
    
    public subscript(dynamicMember option: String) -> Bool {
        return options.contains(option)
    }
    
    var build: Bool { return options.contains("build") }
    
    public init(options: [String] = []) {
        self.options = options
    }
}


internal extension String {
    static let defaultOwnerKey = "DefaultOwner"
}

public struct Repo: Identifiable, Equatable, Hashable {
    public static func == (lhs: Repo, rhs: Repo) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
    static var dictionaryDecoder: DictionaryDecoder {
        let decoder = DictionaryDecoder()
        let defaults: [String:Any] = [
            String(describing: LocalPathDictionary.self): LocalPathDictionary()
        ]
        decoder.missingValueDecodingStrategy = .useDefault(defaults: defaults)
        return decoder
            

    }
    
    public enum State: Int, Codable {
        case failing = 0
        case passing = 1
        case unknown = 2
    }

    public typealias LocalPathDictionary = [String:String]

    public let id: UUID
    public var name: String
    public var owner: String
    public var workflow: String
    public var branches: [String]
    public var state: State
    public var settings: WorkflowSettings
    public var paths: LocalPathDictionary
    public var lastFailed: Date?
    public var lastSucceeded: Date?
    
    public init() {
        id = UUID()
        name = ""
        owner = UserDefaults.standard.string(forKey: .defaultOwnerKey) ?? ""
        workflow = "Tests"
        branches = []
        state = .unknown
        settings = WorkflowSettings()
        paths = [:]
    }
    
    public init(_ name: String, owner: String, workflow: String, id: UUID? = nil, state: State = .unknown, branches: [String] = [], settings: WorkflowSettings = WorkflowSettings()) {
        self.id = id ?? UUID()
        self.name = name
        self.owner = owner
        self.workflow = workflow
        self.branches = branches
        self.state = state
        self.settings = settings
        self.paths = [:]
    }
    
    mutating public func remember(url: URL, forDevice device: String) {
        paths[device] = url.absoluteURL.path
        storeBookmark(for: url)
    }
    
    public func url(forDevice device: String) -> URL? {
        guard let path = paths[device] else { return nil }
        
        let url = URL(fileURLWithPath: path)
        return restoreBookmark(for: url)
    }
    
    
    func storeBookmark(for url: URL) {
        let path = url.absoluteURL.path
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw ActionStatusError.couldntAccessSecurityScope
            }
            
            // Make sure you release the security-scoped resource when you are done.
            defer { url.stopAccessingSecurityScopedResource() }
            
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: "bookmark:\(path)")
        } catch {
            modelChannel.log("Couldn't make bookmark for \(url).\n\(error)")
        }
    }
    
    func restoreBookmark(for url: URL) -> URL {
        let path = url.absoluteURL.path
        if let data = UserDefaults.standard.data(forKey: "bookmark:\(path)") {
            do {
                var isStale = false
                let resolved = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
                if !isStale {
                    return resolved
                }
            } catch {
            modelChannel.log("Couldn't retrieve bookmark for \(url).\n\(error)")
            }
        }
    
        return url
    }

    func state(fromSVG svg: String) -> State {
        if svg.contains("failing") {
            return .failing
        } else if svg.contains("passing") {
            return .passing
        } else {
            return .unknown
        }
    }
    
    public var badgeName: String {
        let name: String
        switch state {
            case .unknown: name = "questionmark.circle"
            case .failing: name = "xmark.circle"
            case .passing: name = "checkmark.circle"
        }
        return name
    }

    public var statusColor: Color {
        switch state {
            case .unknown: return .black
            case .failing: return .red
            case .passing: return .green
        }
    }
    
    func checkState() -> State {
        // TODO: this should probably be more asynchronous
        var newState = State.unknown
        let queries = branches.count > 0 ? branches.map({ "?branch=\($0)" }) : [""]
        for query in queries {
            if let url = URL(string: "https://github.com/\(owner)/\(name)/workflows/\(workflow)/badge.svg\(query)"),
                let data = try? Data(contentsOf: url),
                let svg = String(data: data, encoding: .utf8) {
                    let svgState = state(fromSVG: svg)
                    if newState == .unknown {
                        newState = svgState
                    } else if svgState == .failing {
                        newState = .failing
                    }
            }
        }
        
        return newState
    }
    
    public enum GithubLocation {
        case repo
        case workflow
    }
        
    public func githubURL(for location: GithubLocation = .workflow) -> URL {
        let suffix = location == .workflow ? "/actions?query=workflow%3A\(workflow)" : ""
        return URL(string: "https://github.com/\(owner)/\(name)\(suffix)")!
    }
  }

extension Repo: Codable {
}
