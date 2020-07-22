// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/07/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation


/// Fetches the state of all repos using the SVG status
/// badge that github automatically generates.
///
/// This is a bit of a hack and only gives us the bare
/// details of the state of the repo: passing or failing.

struct SimpleRefreshController: RefreshController {
    internal let model: Model
    internal let timer: OneShotTimer
    
    public typealias RefreshBlock = () -> Void
    public var block: RefreshBlock?
    
    init(model: Model, block: @escaping RefreshBlock) {
        self.model = model
        self.block = block
        self.timer = OneShotTimer()
    }
    
    public func resume() {
        timer.schedule(after: 0) { _ in
            self.doRefresh()
        }
    }
    
    public func pause() {
        if timer.cancel() {
            modelChannel.log("Cancelled refresh.")
        }
    }
}

internal extension SimpleRefreshController {
    func doRefresh() {
        DispatchQueue.global(qos: .background).async {
            modelChannel.log("Refreshing...")
            var newState: [UUID: Repo.State] = [:]
            for (id, repo) in model.items {
                newState[id] = checkState(for: repo)
            }
            
            DispatchQueue.main.async {
                modelChannel.log("Completed Refresh")
                
                for (id, repo) in model.items {
                    if let state = newState[id] {
                        var updated = repo
                        updated.state = state
                        switch state {
                        case .passing: updated.lastSucceeded = Date()
                        case .failing: updated.lastFailed = Date()
                        default: break
                        }
                        model.items[id] = updated
                    }
                }
                
                model.sortItems()
                self.block?()
                timer.schedule(after: model.refreshInterval) { _ in
                    self.doRefresh()
                }
            }
        }
    }
    
    func checkState(for repo: Repo) -> Repo.State {
        var newState = Repo.State.unknown
        let queries = repo.branches.count > 0 ? repo.branches.map({ repo.githubURL(for: .badge($0)) }) : [repo.githubURL(for: .badge(""))]
        for url in queries {
            if let data = try? Data(contentsOf: url),
               let svg = String(data: data, encoding: .utf8) {
                let svgState = repo.state(fromSVG: svg)
                if newState == .unknown {
                    newState = svgState
                } else if svgState == .failing {
                    newState = .failing
                }
            }
        }
        
        return newState
    }
    
}
