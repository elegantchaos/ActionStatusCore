// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/02/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import DictionaryCoding
import Logger
import SwiftUI
import Hardware

let modelChannel = Channel("com.elegantchaos.actionstatus.Model")

public enum ActionStatusError: Error {
    case couldntAccessSecurityScope
}
    
public class Model: ObservableObject {
    public typealias RepoList = [Repo]
    public typealias RefreshBlock = () -> Void
    
    internal let store: NSUbiquitousKeyValueStore
    internal let key: String = "State"
    internal var timer: Timer?
    
    public var block: RefreshBlock?
    public var refreshInterval: Double = 10.0
    
    @Published public var items: [Repo]
    
    public init(_ repos: [Repo], store: NSUbiquitousKeyValueStore = NSUbiquitousKeyValueStore.default, block: RefreshBlock? = nil) {
        self.block = block
        self.store = store
        self.items = repos
        NotificationCenter.default.addObserver(self, selector: #selector(modelChangedExternally), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
    }
}

// MARK: Public

public extension Model {
    var failingCount: Int {
        var count = 0
        for repo in items {
            if repo.state == .failing {
                count += 1
            }
        }
        return count
    }
    
    func load(fromDefaultsKey key: String) {
        let decoder = Repo.dictionaryDecoder
        if let repoIDs = store.array(forKey: key) as? Array<String> {
            var loadedRepos: [Repo] = []
            for repoID in repoIDs {
                if let dict = store.dictionary(forKey: repoID) {
                    do {
                        let repo = try decoder.decode(Repo.self, from: dict)
                        loadedRepos.append(repo)
                    } catch {
                        modelChannel.log("Failed to restore repo data from \(dict).\n\nError:\(error)")
                    }
                }
            }
            items = loadedRepos
            sortItems()
        }
    }
    
    func save(toDefaultsKey key: String) {
        let encoder = DictionaryEncoder()
        var repoIDs: [String] = []
        for repo in items {
            let repoID = repo.id.uuidString
            if let dict = try? encoder.encode(repo) as [String:Any] {
                store.set(dict, forKey: repoID)
                repoIDs.append(repoID)
            }
        }
        store.set(repoIDs, forKey: key)
    }
    
    func repo(withIdentifier id: UUID) -> Repo? {
        return items.first(where: { $0.id == id })
    }
    
    func remember(url: URL, forDevice device: String, inRepo repo: Repo) {
        for n in 0 ..< items.count {
            if items[n].id == repo.id {
                items[n].remember(url: url, forDevice: device)
            }
        }
    }
    
    func refresh() {
        scheduleRefresh(after: 0)
    }
    
    func cancelRefresh() {
        if let timer = timer {
            modelChannel.log("Cancelled refresh.")
            timer.invalidate()
            self.timer = nil
        }
    }
    
    @discardableResult func addRepo() -> Repo {
        let repo = Repo()
        items.append(repo)
        return repo
    }
    
    @discardableResult func addRepo(name: String, owner: String) -> Repo {
        let repo = Repo(name, owner: owner, workflow: "Tests")
        items.append(repo)
        return repo
    }
    
    func add(fromFolders urls: [URL]) {
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let fm = FileManager.default
            for url in urls {
                if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: []) {
                    while let url = enumerator.nextObject() as? URL {
                        if url.lastPathComponent == ".git" {
                            add(fromGitRepo: url, detector: detector)
                        }
                    }
                }
            }
            sortItems()
        }
    }
    
    
    func remove(repo: Repo) {
        if let index = items.firstIndex(of: repo) {
            var updated = items
            updated.remove(at: index)
            items = updated
        }
    }
}

// MARK: Internal

internal extension Model {
    
    @objc func modelChangedExternally() {
        load(fromDefaultsKey: key)
    }
    
    func scheduleRefresh(after interval: TimeInterval) {
        cancelRefresh()
        modelChannel.log("Scheduled refresh for \(interval) seconds.")
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.doRefresh()
        }
    }
    
    func doRefresh() {
        DispatchQueue.global(qos: .background).async {
            modelChannel.log("Refreshing...")
            var newState: [UUID: Repo.State] = [:]
            for repo in self.items {
                newState[repo.id] = repo.checkState()
            }
            
            DispatchQueue.main.async {
                modelChannel.log("Completed Refresh")
                
                for n in 0 ..< self.items.count {
                    if let state = newState[self.items[n].id] {
                        self.items[n].state = state
                        switch state {
                            case .passing: self.items[n].lastSucceeded = Date()
                            case .failing: self.items[n].lastFailed = Date()
                            default: break
                        }
                    }
                }
                
                self.sortItems()
                self.block?()
                self.scheduleRefresh(after: self.refreshInterval)
            }
        }
    }
    
    func sortItems() {
        self.items.sort { (r1, r2) -> Bool in
            if (r1.state == r2.state) {
                return r1.name < r2.name
            }
            
            return r1.state.rawValue < r2.state.rawValue
        }
    }
    
    func add(fromGitRepo localGitFolderURL: URL, detector: NSDataDetector) {
        let containerURL = localGitFolderURL.deletingLastPathComponent()
        let containerName = containerURL.lastPathComponent
        if let config = try? String(contentsOf: localGitFolderURL.appendingPathComponent("config")) {
            let tweaked = config.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
            let range = NSRange(location: 0, length: tweaked.count)
            for result in detector.matches(in: tweaked, options: [], range: range) {
                if let url = result.url, url.scheme == "https", url.host == "github.com" {
                    let name = url.deletingPathExtension().lastPathComponent
                    let owner = url.deletingLastPathComponent().lastPathComponent
                    var repo = items.filter({ $0.name == name && $0.owner == owner }).first
                    if repo == nil {
                        repo = addRepo(name: name, owner: owner)
                    }
                    
                    if repo?.name == containerName, let identifier = Device.main.identifier, let repo = repo {
                        remember(url: containerURL, forDevice: identifier, inRepo: repo)
                        modelChannel.log("Local path for \(repo.name) on machine \(identifier) is \(localGitFolderURL).")
                    }
                }
            }
        }
    }
    
}
