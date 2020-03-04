// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

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

public struct Repo: Identifiable, Equatable {
    public enum State: Int, Codable {
        case failing = 0
        case passing = 1
        case unknown = 2
    }

    public let id: UUID
    public var name: String
    public var owner: String
    public var workflow: String
    public var branches: [String]
    public var state: State
    public var settings: WorkflowSettings
    public var paths: [String:String]
    
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
                    } else if state == .failing {
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
    
//    public func openInGithub(destination: GithubLocation = .workflow) {
//        let suffix = destination == .workflow ? "/actions?query=workflow%3A\(workflow)" : ""
//        if let url = URL(string: "https://github.com/\(owner)/\(name)\(suffix)") {
//            UIApplication.shared.open(url)
//        }
//    }
}

extension Repo: Codable {
}
