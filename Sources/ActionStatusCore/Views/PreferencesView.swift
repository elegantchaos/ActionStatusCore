// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/08/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Keychain
import SwiftUI
import SwiftUIExtensions

public struct PreferencesView: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var viewState: ViewState
    @EnvironmentObject var model: Model
    
    @State var defaultOwner: String = ""
    @State var refreshRate: RefreshRate = .automatic
    @State var displaySize: DisplaySize = .automatic
    @State var showInMenu = true
    @State var showInDock = true
    @State var githubToken = ""
    @State var githubUser = ""
    @State var githubServer = ""
    
    public init() {
    }
    
    public var body: some View {
        AlignedLabelContainer {
        VStack {
            FormHeaderView("Preferences", cancelAction: handleCancel, doneAction: handleSave)
            
                Form() {
                    FormSection(
                        header: "Connection",
                        footer: "Leave the github information blank to fall back on basic status checking (which works for public repos only).",
                        font: viewState.formHeaderFont
                    ) {
                        
                        FormPickerRow(label: "Refresh Every", variable: $refreshRate, cases: RefreshRate.allCases)
                        FormFieldRow(label: "Github User", variable: $githubUser, contentType: .username)
                        FormFieldRow(label: "Github Server", variable: $githubServer, contentType: .URL)
                        FormFieldRow(label: "Github Tokeb", variable: $githubToken, contentType: .password)
                    }
                    
                    FormSection(
                        header: "Display",
                        footer: "Display settings.",
                        font: viewState.formHeaderFont
                    ) {
                        
                        FormPickerRow(label: "Item Size", variable: $displaySize, cases: DisplaySize.allCases)
                        
                        HStack {
                            AlignedLabel("Show In Menubar")
                            Toggle("", isOn: $showInMenu)
                        }
                        
                        HStack {
                            AlignedLabel("Show In Dock")
                            Toggle("", isOn: $showInDock)
                        }
                    }
                    
                    Section(
                        header: Text("Creation").font(viewState.formHeaderFont),
                        footer: Text("Defaults to use for new repos.")
                    ) {
                        HStack {
                            AlignedLabel("Default Owner")
                            TextField("owner", text: $defaultOwner)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                    
                    
                    
            }
        }
        .padding()
        .onAppear(perform: handleAppear)
        }
    }
    
    
    func handleAppear() {
        defaultOwner = model.defaultOwner
        refreshRate = viewState.refreshRate
        displaySize = viewState.displaySize
        showInDock = UserDefaults.standard.bool(forKey: .showInDockKey)
        showInMenu = UserDefaults.standard.bool(forKey: .showInMenuKey)
        githubUser = viewState.githubUser
        githubServer = viewState.githubServer
        if let token = try? Keychain.default.getToken(user: viewState.githubUser, server: viewState.githubServer) {
            githubToken = token
        }
        
    }
    
    func handleCancel() {
        presentation.wrappedValue.dismiss()
    }
    
    func handleSave() {
        model.defaultOwner = defaultOwner
        viewState.refreshRate = refreshRate
        viewState.displaySize = displaySize
        viewState.githubUser = githubUser
        viewState.githubServer = githubServer
        UserDefaults.standard.set(showInDock, forKey: .showInDockKey)
        UserDefaults.standard.set(showInMenu, forKey: .showInMenuKey)
        
        // save token...
        ////            try Keychain.default.addToken("<token>", user: user, server: server)
        
        presentation.wrappedValue.dismiss()
    }
    
}

