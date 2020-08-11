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
    @State private var labelWidth: CGFloat = 0

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
        VStack {
            FormHeaderView("Preferences", cancelAction: handleCancel, doneAction: handleSave)
            
            NavigationView {
                Form() {
                    HStack {
                        Label("Default Owner", width: $labelWidth)
                        TextField("owner", text: $defaultOwner)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    HStack {
                        Label("Refresh Every", width: $labelWidth)
                        Picker(refreshRate.label, selection: $refreshRate) {
                            ForEach(RefreshRate.allCases, id: \.self) { rate in
                                Text(rate.label)
                            }
                        }
                        .setPickerStyle()
                    }
                    
                    HStack {
                        Label("Display Size", width: $labelWidth)
                        Picker(displaySize.label, selection: $displaySize) {
                            ForEach(DisplaySize.allCases, id: \.self) { size in
                                Text(size.label)
                            }
                        }
                        .setPickerStyle()
                    }
                    
                    HStack {
                        Label("Show In Menubar", width: $labelWidth)
                        Toggle("", isOn: $showInMenu)
                    }
                    
                    HStack {
                        Label("Show In Dock", width: $labelWidth)
                        Toggle("", isOn: $showInDock)
                    }

                    
                    HStack {
                        Label("User", width: $labelWidth)
                        TextField("user", text: $githubUser)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    HStack {
                        Label("Server", width: $labelWidth)
                        TextField("server", text: $githubServer)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    HStack {
                        Label("API Token", width: $labelWidth)
                        TextField("token", text: $githubToken)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                }
            }.padding()
        }
        .padding()
        .onAppear(perform: handleAppear)
        .alignLabels(width: $labelWidth)
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


extension View {
    func setPickerStyle() -> some View {
        if #available(iOS 14, *) {
            return AnyView(self.pickerStyle(MenuPickerStyle()))
        } else {
            return AnyView(self.pickerStyle(DefaultPickerStyle()))
        }
    }
}
