// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/08/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions


public struct PreferencesView: View {
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var viewState: ViewState
    
    @State private var labelWidth: CGFloat = 0
    @State var defaultOwner: String = ""
    
    public init() {
    }
    
    public var body: some View {
        VStack {
            FormHeaderView("Preferences", cancelAction: handleCancel, doneAction: handleSave)
            
            NavigationView {
                Form() {
                    HStack {
                        Label("default owner", width: $labelWidth)
                        TextField("owner", text: $defaultOwner)
                        .autocapitalization(.none)
                    }
                    
                    HStack {
                        Label("refresh rate", width: $labelWidth)
                        Picker(viewState.refreshRate.label, selection: $viewState.refreshRate) {
                            ForEach(RefreshRate.allCases, id: \.self) { rate in
                                Text(rate.label)
                            }
                        }
                        .setPickerStyle()
                    }
                    
                    HStack {
                        Label("label size", width: $labelWidth)
                        Picker(viewState.repoTextSize.label, selection: $viewState.repoTextSize) {
                            ForEach(DisplaySize.allCases, id: \.self) { size in
                                Text(size.label)
                            }
                        }
                        .setPickerStyle()
                    }
                }
            }.padding()
        }
        .padding()
        .onAppear(perform: handleAppear)
        .alignLabels(width: $labelWidth)
    }
        
    
    func handleAppear() {
        let defaults = UserDefaults.standard
        defaultOwner = defaults.string(forKey: .defaultOwnerKey) ?? ""
    }
    
    func handleCancel() {
        presentation.wrappedValue.dismiss()
    }

    func handleSave() {
        let defaults = UserDefaults.standard
        defaults.set(defaultOwner, forKey: .defaultOwnerKey)
        
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
