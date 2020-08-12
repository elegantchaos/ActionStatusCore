// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/08/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Keychain
import SwiftUI
import SwiftUIExtensions

public struct FormSection<Content>: View where Content: View {
    @EnvironmentObject var viewState: ViewState
    let header: String
    let footer: String
    let content: () -> Content
    
    public init(header: String, footer: String, @ViewBuilder content: @escaping () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content
    }
    
    public var body: some View {
        Section(
            header: Text(header).font(viewState.formHeaderFont),
            footer: Text(footer)
                .padding(.bottom, 20)
        ) {
            content()
        }
    }
}

public struct FormRow<Content>: View where Content: View {
    let label: String
    @Binding var labelWidth: CGFloat
    let content: () -> Content

    public var body: some View {
        HStack {
            Label(label, width: $labelWidth)
            content()
        }
    }
}

public protocol Labelled: Hashable {
    var label: String { get }
}

public struct FormPickerRow<Variable>: View where Variable: Labelled {
    let label: String
    @Binding var labelWidth: CGFloat
    @Binding var variable: Variable
    let cases: [Variable]

    public var body: some View {
        return FormRow(label: label, labelWidth: $labelWidth) {
            Picker(variable.label, selection: $variable) {
                ForEach(cases, id: \.self) { rate in
                    Text(rate.label)
                }
            }
            .setPickerStyle()
        }
    }
}


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
            
                Form() {
                    FormSection(
                        header: "Connection",
                        footer: "Leave the github information blank to fall back on basic status checking (which works for public repos only).") {
                        
                        FormPickerRow(label: "Refresh Every", labelWidth: $labelWidth, variable: $refreshRate, cases: RefreshRate.allCases)
                        
                        HStack {
                            Label("Github User", width: $labelWidth)
                            TextField("user", text: $githubUser)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        HStack {
                            Label("Github Server", width: $labelWidth)
                            TextField("server", text: $githubServer)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        HStack {
                            Label("Github Token", width: $labelWidth)
                            TextField("token", text: $githubToken)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(4.0)
                                .background(
                                    RoundedRectangle(cornerRadius: 8.0)
                                        .foregroundColor(Color(white: 0.3, opacity: 0.1))
                                )
                        }
                    }
                    
                    Section(
                        header: Text("Display").font(viewState.formHeaderFont),
                        footer: Text("Display settings.")
                    ) {
                        HStack {
                            Label("Item Size", width: $labelWidth)
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
                    }
                    
                    Section(
                        header: Text("Creation").font(viewState.formHeaderFont),
                        footer: Text("Defaults to use for new repos.")
                    ) {
                        HStack {
                            Label("Default Owner", width: $labelWidth)
                            TextField("owner", text: $defaultOwner)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                    
                    
                    
            }
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
