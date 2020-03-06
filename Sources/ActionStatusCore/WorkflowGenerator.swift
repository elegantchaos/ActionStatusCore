// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

public class WorkflowGenerator {
    public let platforms = [
        Job("macOS", name: "macOS", platform: .mac),
        Job("iOS", name: "iOS", platform: .mac),
        Job("tvOS", name: "tvOS", platform: .mac),
        Job("watchOS", name: "watchOS", platform: .mac),
        Job("linux-50", name: "Linux (Swift 5.0)", swift: "5.0"),
        Job("linux-51", name: "Linux (Swift 5.1)", swift: "5.1"),
        Job("linux-52", name: "Linux (Swift 5.2 Nightly)", swift: "nightly-5.2"),
        Job("linux-n", name: "Linux (Swift Nightly)", swift: "nightly"),
    ]
    
    public let configurations = [
        Option("debug", name: "Debug"),
        Option("release", name: "Release")
    ]
    
    public let general = [
        Option("build", name: "Perform Build"),
        Option("test", name: "Run Tests"),
        Option("notify", name: "Post Notifications"),
        Option("upload", name: "Upload Logs"),
        Option("useXcodeForMac", name: "Use Xcode For macOS Target")
    ]
    
    public init() {
    }
    
    func enabledJobs(for repo: Repo) -> [Job] {
        let options = repo.settings.options
        var jobs: [Job] = []
        var macPlatforms: [String] = []
        for platform in platforms {
            if options.contains(platform.id) {
                switch platform.platform {
                    case .mac:
                        macPlatforms.append(platform.id)
                    default:
                        jobs.append(platform)
                }
            }
        }
        
        if macPlatforms.count > 0 {
            let macID = macPlatforms.joined(separator: "-")
            let macName = macPlatforms.joined(separator: "/")
            
            // unless useXcodeForMac is set, remove macOS from the platforms built with xCode
            if !repo.settings.useXcodeForMac, let index = macPlatforms.firstIndex(of: "macOS") {
                macPlatforms.remove(at: index)
            }
            
            // make a catch-all job
            jobs.append(
                Job(macID, name: macName, platform: .mac, xcodePlatforms: macPlatforms)
            )
        }
        
        return jobs
    }

    func enabledConfigs(for repo: Repo) -> [String] {
        let options = repo.settings.options
        return configurations.filter({ options.contains($0.id) }).map({ $0.name })
    }

    public func toggleSet(for options: [Option], in settings: WorkflowSettings) -> [Bool] {
        var toggles: [Bool] = []
        for option in options {
            toggles.append(settings.options.contains(option.id))
        }
        return toggles
    }
    
    public func enabledIdentifiers(for options: [Option], toggleSet toggles: [Bool]) -> [String] {
        var identifiers: [String] = []
        for n in 0 ..< options.count {
            if toggles[n] {
                identifiers.append(options[n].id)
            }
        }
        return identifiers
    }
    
    public func generateWorkflow(for repo: Repo) -> String {
        var source =
        """
        name: \(repo.workflow)
        
        on: [push, pull_request]
        
        jobs:
        
        """
        
        for job in enabledJobs(for: repo) {
            source.append(job.yaml(repo: repo, configurations: enabledConfigs(for: repo)))
        }
        
        return source
    }
}
