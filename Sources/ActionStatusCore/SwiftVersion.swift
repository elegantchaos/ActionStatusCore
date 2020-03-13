// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/03/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public class SwiftVersion: Option {
    public enum XcodeMode {
        case latest
        case toolchain(branch: String)
    }
    
    let short: String
    let linux: String
    let mac: XcodeMode
    
    public init(_ id: String, name: String, short: String, linux: String, mac: XcodeMode) {
        self.short = short
        self.linux = linux
        self.mac = mac
        super.init(id, name: name)
    }
}
