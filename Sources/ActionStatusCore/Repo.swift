// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import Files
import DictionaryCoding

@dynamicMemberLookup public struct WorkflowSettings: Codable, Equatable {
    public var options: [String] = []
    
    public subscript(dynamicMember option: String) -> Bool {
        return options.contains(option)
    }
    
    public init(options: [String] = []) {
        self.options = options
    }
}


private extension String {
    static let defaultOwnerKey = "DefaultOwner"
}

private extension URL {
    var bookmarkKey: String { "bookmark:\(absoluteURL.path)" }
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
    
    public enum State: UInt, Codable {
        case unknown = 0
        case passing = 1
        case failing = 2
        case queued = 3
        case running = 4
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
    
    public static var defaultName: String { "New Repo" }
    public static var defaultOwner: String { UserDefaults.standard.string(forKey: .defaultOwnerKey) ?? "" }
    public static var defaultWorkflow: String { "Tests" }
    public static var defaultBranches: [String] { [] }

    public init() {
        id = UUID()
        name = Self.defaultName
        owner = Self.defaultOwner
        workflow = Self.defaultWorkflow
        branches = Self.defaultBranches
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
    
    public func url(forDevice device: String?) -> URL? {
        guard let device = device, let path = paths[device] else { return nil }
        
        let url = URL(fileURLWithPath: path)
        return restoreBookmark(for: url)
    }
    
    
    func storeBookmark(for url: URL) {
        if let bookmark = url.secureBookmark() {
            UserDefaults.standard.set(bookmark, forKey: url.bookmarkKey)
            modelChannel.log("Stored local bookmark data for \(url.lastPathComponent).")
        } else {
            modelChannel.log("Couldn't make bookmark for \(url.lastPathComponent)")
        }
    }
    
    func restoreBookmark(for url: URL) -> URL {
        guard let data = UserDefaults.standard.data(forKey: url.bookmarkKey) else {
            modelChannel.log("No bookmark stored for \(url.lastPathComponent)")
            return url
        }
        
        guard let resolved = URL.resolveSecureBookmark(data) else {
            modelChannel.log("Couldn't resolve bookmark for \(url.lastPathComponent)")
            return url
        }
        
        modelChannel.log("Resolved local bookmark data for \(url.lastPathComponent).")
        return resolved
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
            case .running: name = "arrow.triangle.2.circlepath"
            case .queued: name = "clock.arrow.circlepath"
        }
        return name
    }

    public var statusColor: Color {
        switch state {
            case .failing: return .red
            case .passing: return .green
            default: return .black
        }
    }
    
    public enum GithubLocation {
        case repo
        case workflow
        case releases
        case actions
        case badge(String)
    }
        
    public func githubURL(for location: GithubLocation = .workflow) -> URL {
        let suffix: String
        switch location {
            case .workflow: suffix = "/actions?query=workflow%3A\(workflow)"
            case .releases: suffix = "/releases"
            case .actions: suffix = "/actions"
            case .badge(let branch):
                let query = branch.isEmpty ? "" : "?branch=\(branch)"
                suffix = "/workflows/\(workflow)/badge.svg\(query)"
                
            default: suffix = ""
        }
        
        return URL(string: "https://github.com/\(owner)/\(name)\(suffix)")!
    }
    
    public enum ImgShieldLocation {
        case release
    }
    
    public func imgSheildURL(suffix: String) -> URL {
        return URL(string: "https://img.shields.io/\(suffix)")!
    }
    
    public func imgShieldURL(for type: ImgShieldLocation) -> URL {
        let suffix: String
        switch type {
            case .release: suffix = "github/v/release/\(owner)/\(name)"
        }
        
        return imgSheildURL(suffix: suffix)
    }

    public func imgShieldURL(for compiler: Compiler) -> URL {
        return imgSheildURL(suffix: "badge/swift-\(compiler.short)-F05138.svg")
    }

    public func imgShieldURL(forPlatforms platforms: [String]) -> URL {
        let platformBadges = platforms.joined(separator: "_")
        return imgSheildURL(suffix: "badge/platforms-\(platformBadges)-lightgrey.svg?style=flat")
    }

}

extension Repo: Codable {
}
