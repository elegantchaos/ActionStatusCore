// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

public extension UIApplication {
    var isTestingUI : Bool {
        guard let testingFlag = ProcessInfo.processInfo.environment["UITesting"], testingFlag == "YES" else { return false }
        return true
    }
}

public extension Dictionary where Key == String, Value == String {
    var isTestingUI: Bool {
        get { self["UITesting"] == "YES" }
        set { self["UITesting"] = newValue ? "YES" : "NO" }
    }
}
