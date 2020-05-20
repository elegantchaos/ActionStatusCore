// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

public class TestModel: Model {
    public let repos: [Repo]
    
    public init() {
        repos = [
            Repo("ApplicationExtensions", owner: "elegantchaos", workflow: "Tests", state: .failing),
            Repo("Datastore", owner: "elegantchaos", workflow: "Swift", state: .passing),
            Repo("DatastoreViewer", owner: "elegantchaos", workflow: "Build", state: .failing),
            Repo("Logger", owner: "elegantchaos", workflow: "tests", state: .unknown),
            Repo("ViewExtensions", owner: "elegantchaos", workflow: "Tests", state: .passing),
        ]

        super.init(repos)
    }
    
    public override func load(fromDefaultsKey key: String) {
    }
    
    public override func save(toDefaultsKey key: String) {
    }
    
    public override func refresh() {
    }
}
