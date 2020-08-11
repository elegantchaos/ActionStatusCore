// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/08/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

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
    }
    
    func handleCancel() {
        presentation.wrappedValue.dismiss()
    }

    func handleSave() {
        model.defaultOwner = defaultOwner
        viewState.refreshRate = refreshRate
        viewState.displaySize = displaySize
        UserDefaults.standard.set(showInDock, forKey: .showInDockKey)
        UserDefaults.standard.set(showInMenu, forKey: .showInMenuKey)
        
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
