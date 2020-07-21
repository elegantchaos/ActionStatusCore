// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/02/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import BindingsExtensions

struct GenerateView: View {
    let generator = Generator()
    let repoID: UUID
    
    @EnvironmentObject var model: Model
    @EnvironmentObject var viewState: ViewState
    @Environment(\.presentationMode) var presentation
    
    @State var platforms: [Bool] = []
    @State var compilers: [Bool] = []
    @State var configurations: [Bool] = []
    @State var general: [Bool] = []

    var repo: Repo {
        model.repo(withIdentifier: repoID)!
    }
    
    var body: some View {
        VStack {
            FormHeaderView(repo.name, cancelAction: onCancel, doneLabel: "Save", doneAction: onGenerate)
            
            Text("Settings for workflow '\(repo.workflow).yml' in repo \(repo.owner)/\(repo.name).")
                .font(.caption)
                .padding(.top, viewState.padding)

            Form() {
                
                togglesSection(title: "Platforms", options: self.generator.platforms, toggles: $platforms)
                togglesSection(title: "Swift", options: self.generator.compilers, toggles: $compilers)
                togglesSection(title: "Configuration", options: self.generator.configurations, toggles: $configurations)
                togglesSection(title: "Other Options", options: self.generator.general, toggles: $general)
            }.padding()
        }
        .padding()
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
    }
    
    func onAppear() {
        fetchSettings()
    }
    
    func onDisappear() {
        storeSettings()
    }
    
    func onCancel() {
        presentation.wrappedValue.dismiss()
    }

    func onGenerate() {
        let host = viewState.host
        storeSettings()
        if let output = generator.generateWorkflow(for: repo, application: host.info) {
            host.save(output: output)
        }
        viewState.saveState()
    }
    
    func fetchSettings() {
        let settings = repo.settings
        platforms = generator.toggleSet(for: generator.platforms, in: settings)
        compilers = generator.toggleSet(for: generator.compilers, in: settings)
        configurations = generator.toggleSet(for: generator.configurations, in: settings)
        general = generator.toggleSet(for: generator.general, in: settings)
    }
    
    func storeSettings() {
        var options: [String] = []
        options.append(contentsOf: generator.enabledIdentifiers(for: generator.platforms, toggleSet: platforms))
        options.append(contentsOf: generator.enabledIdentifiers(for: generator.compilers, toggleSet: compilers))
        options.append(contentsOf: generator.enabledIdentifiers(for: generator.configurations, toggleSet: configurations))
        options.append(contentsOf: generator.enabledIdentifiers(for: generator.general, toggleSet: general))
        var updated = repo
        updated.settings.options = options
        model.update(repo: updated)
    }
    
    func togglesSection(title: String, options: [Option], toggles: Binding<[Bool]>) -> some View {
        let count = toggles.wrappedValue.count
        let allSet = toggles.wrappedValue.filter({ $0 }).count == count
        return Section(header:
            HStack {
                Text(title).font(viewState.formHeaderFont)
                Spacer()
                Button(action: {
                    for n in 0 ..< toggles.wrappedValue.count {
                        toggles[n].wrappedValue = !allSet
                    }
                }) {
                    Text(allSet ? "disable all" : "enable all")
                        
                }
            }
        ) {
            return VStack {
                ForEach(0 ..< count, id: \.self) { index in
                    Toggle(isOn: toggles[index]) {
                        Text(options[index].label)
                    }
                }
            }
        }
    }
 
}


struct ComposeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PreviewContext()
        return context.inject(into: GenerateView(repoID: context.testRepo.id))
    }
}
