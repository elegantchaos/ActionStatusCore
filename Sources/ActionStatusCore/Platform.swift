// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

public class Platform: Option {
    let subPlatforms: [Platform]
    let xcodeDestination: String?
    
    public init(_ id: String, name: String, xcodeDestination: String? = nil, subPlatforms: [Platform] = []) {
        self.xcodeDestination = xcodeDestination
        self.subPlatforms = subPlatforms
        super.init(id, name: name)
    }

    public override var label: String {
        if xcodeDestination == nil {
            return name
        } else {
            return "\(name) (xcodebuild)"
        }
    }
    
    public func yaml(repo: Repo, compilers: [Compiler], configurations: [String]) -> String {
        let settings = repo.settings
        let package = repo.name
        let test = settings.test
        let build = settings.build
        
        var yaml = ""
        var xcodeToolchain: String? = nil
        
        for compiler in compilers {
            var job =
            """
            
                \(id)-\(compiler.id):
                    name: \(name) (\(compiler.name))
            """
            
            containerYAML(&job, compiler, &xcodeToolchain)
            commonYAML(&job)
            
            if let branch = xcodeToolchain {
                toolchainYAML(&job, branch)
            }
            
            if subPlatforms.isEmpty {
                job.append(swiftYAML(configurations: configurations, build: build, test: test, customToolchain: xcodeToolchain != nil, compiler: compiler))
            } else {
                job.append(xcodebuildCommonYAML())
                for platform in subPlatforms {
                    job.append(platform.xcodebuildYAML(configurations: configurations, package: package, build: build, test: test))
                }
            }
            
            if settings.upload {
                uploadYAML(&job)
            }
            
            if settings.notify {
                job.append(notifyYAML(compiler: compiler))
            }
            
            yaml.append("\(job)\n\n")
        }
        
        return yaml
    }

    fileprivate func swiftYAML(configurations: [String], build: Bool, test: Bool, customToolchain: Bool, compiler: Compiler) -> String {
        var yaml = ""
        let pathFix = customToolchain ? "export PATH=\"swift-latest:$PATH\"; " : ""
        if build {
            for config in configurations {
                yaml.append(
                    """
                    
                            - name: Build (\(config))
                              run: \(pathFix)swift build -c \(config.lowercased())
                    """
                )
            }
        }
        
        if test {
            for config in configurations {
                let buildForTesting = config == "Release" ? "-Xswiftc -enable-testing" : ""
                let discovery = (compiler.id != "swift-50") && !((compiler.id == "swift-51") && (config == "Release")) ? "--enable-test-discovery" : ""
                yaml.append(
                    """
                    
                            - name: Test (\(config))
                              run: \(pathFix)swift test --configuration \(config.lowercased()) \(buildForTesting) \(discovery)
                    """
                )
            }
        }
        return yaml
    }

    fileprivate func xcodebuildCommonYAML() -> String {
        var yaml = ""
        yaml.append(
            """
            
                    - name: Xcode Version
                      run: xcodebuild -version
                    - name: XC Pretty
                      run: sudo gem install xcpretty-travis-formatter
            """
        )
        return yaml
    }

    fileprivate func xcodebuildYAML(configurations: [String], package: String, build: Bool, test: Bool) -> String {
        var yaml = ""
        let destinationName = xcodeDestination ?? ""
        let destination = destinationName.isEmpty ? "" : "-destination \"name=\(destinationName)\""
        yaml.append(
            """
            
                    - name: Detect Workspace & Scheme (\(name))
                      run: |
                        WORKSPACE="\(package).xcworkspace"
                        if [[ ! -e "$WORKSPACE" ]]
                        then
                        WORKSPACE="."
                        GOTPACKAGE=$(xcodebuild -workspace . -list | (grep \(package)-Package || true))
                        if [[ $GOTPACKAGE != "" ]]
                        then
                        SCHEME="\(package)-Package"
                        else
                        SCHEME="\(package)"
                        fi
                        else
                        SCHEME="\(package)-\(name)"
                        fi
                        echo "set -o pipefail; export PATH='swift-latest:$PATH'; WORKSPACE='$WORKSPACE'; SCHEME='$SCHEME'" > setup.sh
            """
        )
        
        if build {
            for config in configurations {
                yaml.append(
                    """
                    
                            - name: Build (\(name) \(config))
                              run: |
                                source "setup.sh"
                                echo "Building workspace $WORKSPACE scheme $SCHEME."
                                xcodebuild clean build -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration \(config) CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | tee logs/xcodebuild-\(id)-build-\(config.lowercased()).log | xcpretty
                    """
                )
            }
        }
        
        if test && (id != "watchOS") {
            for config in configurations {
                let extraArgs = config == "Release" ? "ENABLE_TESTABILITY=YES" : ""
                yaml.append(
                    """
                    
                            - name: Test (\(name) \(config))
                              run: |
                                source "setup.sh"
                                echo "Testing workspace $WORKSPACE scheme $SCHEME."
                                xcodebuild test -workspace "$WORKSPACE" -scheme "$SCHEME" \(destination) -configuration \(config) CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \(extraArgs) | tee logs/xcodebuild-\(id)-test-\(config.lowercased()).log | xcpretty
                    """
                )
            }
        }
        
        return yaml
    }
    
    fileprivate func uploadYAML(_ yaml: inout String) {
        yaml.append(
            """

                    - name: Upload Logs
                      uses: actions/upload-artifact@v1
                      with:
                        name: logs
                        path: logs
            """
        )
    }
    
    fileprivate func notifyYAML(compiler: Compiler) -> String {
        var yaml = ""
        yaml.append(
            """
            
                    - name: Slack Notification
                      uses: elegantchaos/slatify@master
                      if: always()
                      with:
                        type: ${{ job.status }}
                        job_name: '\(name) (\(compiler.name))'
                        mention_if: 'failure'
                        url: ${{ secrets.SLACK_WEBHOOK }}
            """
        )
        return yaml
    }
    
    fileprivate func toolchainYAML(_ yaml: inout String, _ branch: String) {
        yaml.append(
            """
            
                    - name: Install Toolchain
                      run: |
                        branch="\(branch)"
                        wget --quiet https://swift.org/builds/$branch/xcode/latest-build.yml
                        grep "download:" < latest-build.yml > filtered.yml
                        sed -e 's/-osx.pkg//g' filtered.yml > stripped.yml
                        sed -e 's/:[^:\\/\\/]/YML="/g;s/$/"/g;s/ *=/=/g' stripped.yml > snapshot.sh
                        source snapshot.sh
                        echo "Installing Toolchain: $downloadYML"
                        wget --quiet https://swift.org/builds/$branch/xcode/$downloadYML/$downloadYML-osx.pkg
                        sudo installer -pkg $downloadYML-osx.pkg -target /
                        ln -s "/Library/Developer/Toolchains/$downloadYML.xctoolchain/usr/bin" swift-latest
                        export PATH="swift-latest:$PATH"
                        swift --version
            """
        )
    }
    
    fileprivate func containerYAML(_ yaml: inout String, _ compiler: Compiler, _ xcodeToolchain: inout String?) {
        switch id {
            case "linux":
                yaml.append(
                    """
                    
                            runs-on: ubuntu-latest
                            container: \(compiler.linux)
                    """
            )
            
            default:
                yaml.append(
                    """

                            runs-on: macOS-latest
                    """
                )
                
                switch compiler.mac {
                    case .latest: break
                    case .toolchain(let branch): xcodeToolchain = branch
            }
        }
    }
    
    fileprivate func commonYAML(_ yaml: inout String) {
        yaml.append(
            """

                    steps:
                    - name: Checkout
                      uses: actions/checkout@v1
                    - name: Swift Version
                      run: swift --version
                    - name: Make Logs Directory
                      run: mkdir logs
            """
        )
    }
}

