// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/03/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import DictionaryCoding
@testable import ActionStatusCore

final class ActionStatusCoreTests: XCTestCase {

    var version1: [String:Any] = [
        "name": "Name",
        "workflow": "Test",
        "state": 1,
        "branches": [ "master" ],
        "owner": "Owner",
        "id": "DBDD302B-B50A-47DC-AA5E-4FAF2FF8A01A",
        "settings": [
            "options": [ "test" ]
        ]
    ]

    var version2: [String:Any] = [ // added `paths`
        "name": "Name",
        "workflow": "Test",
        "state": 1,
        "branches": [ "master" ],
        "owner": "Owner",
        "id": "DBDD302B-B50A-47DC-AA5E-4FAF2FF8A01A",
        "settings": [
            "options": [ "test" ]
        ],
        "paths": [
            "machine1": "path1"
        ]
    ]

    func outputRepo() {
        let settings = WorkflowSettings(options: ["test"])
        let repo = Repo("Name", owner: "Owner", workflow: "Test", id: UUID(), state: .passing, branches: ["master"], settings: settings)
        let encoder = DictionaryEncoder()
        if let dictionary: [String:Any] = try? encoder.encode(repo) {
            let data = try! JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted])
            let json = String(data: data, encoding: .utf8)!
            print(json)
        }
    }
    
    func testLoadVersion1Repo() {
        typealias LocalPathDictionary = [String:String]
        
        let decoder = DictionaryDecoder()
        let defaults: [String:Any] = [
            String(describing: LocalPathDictionary.self): LocalPathDictionary()
        ]
            
        decoder.missingValueDecodingStrategy = .useDefault(defaults: defaults)
        
        do {
            let repo = try decoder.decode(Repo.self, from: version1)
            XCTAssertEqual(repo.name, "Name")
            XCTAssertEqual(repo.owner, "Owner")
            XCTAssertEqual(repo.workflow, "Test")
            XCTAssertEqual(repo.state, .passing)
            XCTAssertEqual(repo.branches, [ "master" ])
            XCTAssertEqual(repo.id, UUID(uuidString: "DBDD302B-B50A-47DC-AA5E-4FAF2FF8A01A"))
            XCTAssertEqual(repo.paths, [:])
        } catch {
            XCTFail("couldn't decode: \(error)")
        }
        
    }

    func testLoadVersion2Repo() {
        typealias LocalPathDictionary = [String:String]
        
        let decoder = DictionaryDecoder()
        let defaults: [String:Any] = [
            String(describing: LocalPathDictionary.self): LocalPathDictionary()
        ]
            
        decoder.missingValueDecodingStrategy = .useDefault(defaults: defaults)
        
        do {
            let repo = try decoder.decode(Repo.self, from: version2)
            XCTAssertEqual(repo.name, "Name")
            XCTAssertEqual(repo.owner, "Owner")
            XCTAssertEqual(repo.workflow, "Test")
            XCTAssertEqual(repo.state, .passing)
            XCTAssertEqual(repo.branches, [ "master" ])
            XCTAssertEqual(repo.id, UUID(uuidString: "DBDD302B-B50A-47DC-AA5E-4FAF2FF8A01A"))
            XCTAssertEqual(repo.paths, ["machine1":"path1"])
        } catch {
            XCTFail("couldn't decode: \(error)")
        }
        
    }

}
