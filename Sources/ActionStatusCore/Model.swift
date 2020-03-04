// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 12/02/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import DictionaryCoding

public class Model: ObservableObject {
    public typealias RepoList = [Repo]
    public typealias RefreshBlock = () -> Void
    
    let store: NSUbiquitousKeyValueStore
    let key: String = "State"
    public var block: RefreshBlock?
    var timer: Timer?
    var composingID: UUID?
    public var exportURL: URL?
    var exportYML: String?
    public var refreshInterval: Double = 10.0
    
    @Published public var items: [Repo]
    @Published public var isComposing = false
    @Published public var isSaving = false
    
    public init(_ repos: [Repo], store: NSUbiquitousKeyValueStore = NSUbiquitousKeyValueStore.default, block: RefreshBlock? = nil) {
        self.block = block
        self.store = store
        self.items = repos
        NotificationCenter.default.addObserver(self, selector: #selector(modelChangedExternally), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
    }
    
    @objc func modelChangedExternally() {
        load(fromDefaultsKey: key)
    }

    public var failingCount: Int {
        var count = 0
        for repo in items {
            if repo.state == .failing {
                count += 1
            }
        }
        return count
    }
    
    public func showComposeWindow(for repo: Repo) {
        composingID = repo.id
        isSaving = false
        isComposing = true
        exportURL = nil
        exportYML = ""
    }
    
    public func hideComposeWindow() {
        isComposing = false
    }
    
    public func repoToCompose() -> Repo {
        return items.first(where: { $0.id == composingID })!
    }
    
    public func load(fromDefaultsKey key: String) {
        let decoder = DictionaryDecoder()
        if let repoIDs = store.array(forKey: key) as? Array<String> {
            var loadedRepos: [Repo] = []
            for repoID in repoIDs {
                if let dict = store.dictionary(forKey: repoID) {
                    if let repo = try? decoder.decode(Repo.self, from: dict) {
                        loadedRepos.append(repo)
                    }
                }
            }
            items = loadedRepos
            sortItems()
        }
    }
    
    public func save(toDefaultsKey key: String) {
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

    public func refresh() {
        scheduleRefresh(after: 0)
    }
        
    public func cancelRefresh() {
        if let timer = timer {
            print("Cancelled refresh.")
            timer.invalidate()
            self.timer = nil
        }
    }
    
    func scheduleRefresh(after interval: TimeInterval) {
        cancelRefresh()
        print("Scheduled refresh for \(interval) seconds.")
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.doRefresh()
        }
    }
    
    func doRefresh() {
        DispatchQueue.global(qos: .background).async {
            print("Refreshing...")
            var newState: [UUID: Repo.State] = [:]
            for repo in self.items {
                newState[repo.id] = repo.checkState()
            }
            
            DispatchQueue.main.async {
                print("Completed Refresh")
                
                for n in 0 ..< self.items.count {
                    if let state = newState[self.items[n].id] {
                        self.items[n].state = state
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
    
    @discardableResult public func addRepo() -> Repo {
        let repo = Repo()
        items.append(repo)
        return repo
    }
    
    @discardableResult public func addRepo(name: String, owner: String) -> Repo {
        let repo = Repo(name, owner: owner, workflow: "Tests")
        items.append(repo)
        return repo
    }
    
    public func add(fromFolders urls: [URL]) {
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
    
    func add(fromGitRepo url: URL, detector: NSDataDetector) {
        if let config = try? String(contentsOf: url.appendingPathComponent("config")) {
            let tweaked = config.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
            let range = NSRange(location: 0, length: tweaked.count)
            for result in detector.matches(in: tweaked, options: [], range: range) {
                if let url = result.url, url.scheme == "https", url.host == "github.com" {
                    let name = url.deletingPathExtension().lastPathComponent
                    let owner = url.deletingLastPathComponent().lastPathComponent
                    let existing = items.filter({ $0.name == name && $0.owner == owner })
                    if existing.count == 0 {
                        addRepo(name: name, owner: owner)
                    }
                }
            }
        }
    }
    

    public func remove(repo: Repo) {
        if let index = items.firstIndex(of: repo) {
            var updated = items
            updated.remove(at: index)
            items = updated
        }
    }
}
