// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

public class Job: Option {
    public enum Platform {
        case mac
        case linux
    }
    
    let swift: String?
    public let platform: Platform
    let xcodePlatforms: [String]
    
    public init(_ id: String, name: String, platform: Platform = .linux, swift: String? = nil, xcodePlatforms: [String] = []) {
        self.platform = platform
        self.swift = swift
        self.xcodePlatforms = xcodePlatforms
        super.init(id, name: name)
    }

    public func yaml(repo: Repo, configurations: [String]) -> String {
        let settings = repo.settings
        let package = repo.name
        let test = settings.test
        let build = settings.build
        
        var yaml =
            """
                \(id):
                    name: \(name)
            """
        
        switch (platform) {
            case .mac:
            yaml.append(
            """

                    runs-on: macOS-latest
            """
            )
            
            case .linux:
                let swift = self.swift ?? "5.1"
                yaml.append(
            """

                    runs-on: ubuntu-latest
                    container: swift:\(swift)
            """
                )
        }
        
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

        if xcodePlatforms.count > 0 {
            yaml.append(
                """

                        - name: Xcode Version
                          run: xcodebuild -version
                        - name: XC Pretty
                          run: sudo gem install xcpretty-travis-formatter
                        - name: Detect Workspace & Scheme
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
                                MACOS_SCHEME="$SCHEME"
                                IOS_SCHEME="$SCHEME"
                                TVOS_SCHEME="$SCHEME"
                            else
                                MACOS_SCHEME="\(package)-macOS"
                                IOS_SCHEME="\(package)-iOS"
                                TVOS_SCHEME="\(package)-tvOS"
                            fi
                            echo "WORKSPACE='$WORKSPACE'; SCHEME='$MACOS_SCHEME'" > names-macOS.sh
                            echo "WORKSPACE='$WORKSPACE'; SCHEME='$IOS_SCHEME'" > names-iOS.sh
                            echo "WORKSPACE='$WORKSPACE'; SCHEME='$TVOS_SCHEME'" > names-tvOS.sh
                """
            )
        }
        
        if !xcodePlatforms.contains("macOS") {
            if build {
                for config in configurations {
                    yaml.append(
                        """
                        
                                - name: Build (\(config))
                                  run: swift build -v -c \(config.lowercased())
                        """
                    )
                }
            }

            if test {
                for config in configurations {
                    let extraArgs = config == "Release" ? "-Xswiftc -enable-testing" : ""
                    yaml.append(
                        """
                        
                                - name: Test (\(config))
                                  run: swift test -v -c \(config.lowercased()) \(extraArgs)
                        """
                    )
                }
            }
        }
        
        for platform in xcodePlatforms {
            let destination: String
            switch platform {
                case "iOS":
                    destination = "-destination \"name=iPhone 11\""
                case "tvOS":
                    destination = "-destination \"name=Apple TV\""
                case "watchOS":
                    destination = "-destination \"name=Apple Watch Series 5 - 44mm\""
                default:
                    destination = ""
            }

            if build {
                for config in configurations {
                    yaml.append(
                        """
                        
                                - name: Build (\(platform)/\(config))
                                  run: |
                                    set -o pipefail
                                    source "names-\(platform).sh"
                                    xcodebuild clean build -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration \(config) CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | tee logs/xcodebuild-\(platform)-build-\(config.lowercased()).log | xcpretty
                        """
                    )
                }
            }

            if test && (platform != "watchOS") {
                for config in configurations {
                    let extraArgs = config == "Release" ? "ENABLE_TESTABILITY=YES" : ""
                    yaml.append(
                        """
                        
                                - name: Test (\(platform)/\(config))
                                  run: |
                                    set -o pipefail
                                    source "names-\(platform).sh"
                                    xcodebuild test -workspace "$WORKSPACE" -scheme "$SCHEME" \(destination) -configuration \(config) CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \(extraArgs) | tee logs/xcodebuild-\(platform)-test-\(config.lowercased()).log | xcpretty
                        """
                    )
                }
            }
        }

        if settings.upload {
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


        if settings.notify {
            yaml.append(
                """
                
                        - name: Slack Notification
                          uses: elegantchaos/slatify@master
                          if: always()
                          with:
                            type: ${{ job.status }}
                            job_name: '\(name)'
                            mention_if: 'failure'
                            url: ${{ secrets.SLACK_WEBHOOK }}
                """
            )
        }

        yaml.append("\n\n")
        
        return yaml
    }
 }

