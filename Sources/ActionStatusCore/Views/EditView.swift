// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions
import Hardware


public struct EditView: View {
    #if os(tvOS)
    static let fieldStyle = DefaultTextFieldStyle()
    #else
    static let fieldStyle = RoundedBorderTextFieldStyle()
    #endif

    let repoID: UUID?
    
    @State private var labelWidth: CGFloat = 0

    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var model: Model
    @EnvironmentObject var viewState: ViewState
    
    var title: String { return repoID == nil ? "Add Repository" : "Edit Repository" }
    var repo: Repo? {
        guard let repoID = repoID, let repo = model.repo(withIdentifier: repoID) else { return nil }
        return repo
    }
    
    @State var name = ""
    @State var owner = ""
    @State var workflow = ""
    @State var branches: String = ""
    
    public init(repoID: UUID? = nil) {
        self.repoID = repoID
    }
    
    public var body: some View {
        let localPath = repo?.url(forDevice: Device.main.identifier)?.path ?? ""
        
        return VStack() {
            FormHeaderView(title, cancelAction: dismiss, doneAction: done)

            Form {
                EmptyView()
                
                Section(
                    header: Text("Details").font(viewState.formHeaderFont),
                    footer: Text("Enter the name and owner of the repository, and the name of the workflow file to test. Enter a list of specific branches to test, or leave blank to just test the default branch.")
                ) {
                    HStack {
                        Label("name", width: $labelWidth)
                        TextField("github repo name", text: $name)
                            .nameOrgStyle()
                            .modifier(ClearButton(text: $name))
                        //                        .introspectTextField { textField in
                        //                            textField.becomeFirstResponder()
                        //                        }
                    }
                    
                    HStack {
                        Label("owner", width: $labelWidth)
                        TextField("github user or organisation", text: $owner)
                            .nameOrgStyle()
                            .modifier(ClearButton(text: $owner))
                    }
                    
                    HStack {
                        Label("workflow", width: $labelWidth)
                        TextField("Tests.yml", text: $workflow)
                            .nameOrgStyle()
                            .modifier(ClearButton(text: $workflow))
                    }
                    
                    HStack {
                        Label("branches", width: $labelWidth)
                        TextField("branch1, branch2, …", text: $branches)
                            .branchListStyle()
                            .modifier(ClearButton(text: $branches))
                    }
                    
                }.padding([.bottom])
                
                Section(
                    header: Text("Locations").font(viewState.formHeaderFont),
                    footer: Text("Corresponding locations on Github.")
                ) {
                    HStack(alignment: .firstTextBaseline) {
                        Label("repo", width: $labelWidth)
                        Text("https://github.com/\(trimmedOwner)/\(trimmedName)").bold()
                        Spacer()
                        Button(action: openRepo) {
                            SystemImage("arrowshape.turn.up.right.circle")
                        }
                    }
                    
                    HStack(alignment: .firstTextBaseline) {
                        Label("status", width: $labelWidth)
                        Text("https://github.com/\(trimmedOwner)/\(trimmedName)/actions?query=workflow%3A\(trimmedWorkflow)").bold()
                        Spacer()
                        Button(action: openWorkflow) {
                            SystemImage("arrowshape.turn.up.right.circle")
                        }
                    }

                    if !localPath.isEmpty {
                        HStack(alignment: .firstTextBaseline) {
                            Label("local", width: $labelWidth)
                            Text(localPath)
                        }
                    }

                }
            }
        }
        .onAppear() {
            viewState.host.pauseRefresh()
            self.load()
        }
        .alignLabels(width: $labelWidth)
        
    }
    
    func openRepo() {
        viewState.host.openGithub(with: update(repo: Repo(model: model)), at: .repo)
    }
    
    func openWorkflow() {
        viewState.host.openGithub(with: update(repo: Repo(model: model)), at: .workflow)
    }

    var trimmedWorkflow: String {
        var stripped = workflow.trimmingCharacters(in: .whitespaces)
        if let range = stripped.range(of: ".yml") {
            stripped.removeSubrange(range)
        }
        if stripped.isEmpty {
            stripped = "Tests"
        }
        return stripped
    }
    
    var trimmedName: String {
        return name.trimmingCharacters(in: .whitespaces)
    }
    
    var trimmedOwner: String {
        return owner.trimmingCharacters(in: .whitespaces)
    }
    
    var trimmedBranches: [String] {
        return branches.split(separator: ",").map({ String($0.trimmingCharacters(in: .whitespaces)) })
    }
    
    func dismiss() {
        viewState.host.resumeRefresh()
        presentation.wrappedValue.dismiss()
    }
    
    func done() {
        save()
        dismiss()
    }
    
    func load() {
        if let repoID = repoID, let repo = model.repo(withIdentifier: repoID) {
            name = repo.name
            owner = repo.owner
            workflow = repo.workflow
            branches = repo.branches.joined(separator: ", ")
        }
    }
    
    func save() {
        let repo = self.repo ?? Repo(model: model)
        let updated = update(repo: repo)
        model.update(repo: updated)
    }
    
    func update(repo: Repo) -> Repo {
        var updated = repo
        updated.name = trimmedName
        updated.owner = trimmedOwner
        updated.workflow = trimmedWorkflow
        updated.branches = trimmedBranches
        updated.state = .unknown
        return updated
    }
}


struct RepoEditView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PreviewContext()
        return context.inject(into: EditView(repoID: context.testRepo.id))
    }
}

extension View {
    func nameOrgStyle() -> some View {

        return textFieldStyle(EditView.fieldStyle)
            .keyboardType(.namePhonePad)
            .shim.textContentType(.name)
            .disableAutocorrection(true)
            .autocapitalization(.none)
    }

    func branchListStyle() -> some View {
        return textFieldStyle(EditView.fieldStyle)
            .keyboardType(.alphabet)
            .disableAutocorrection(true)
            .autocapitalization(.none)
    }

}
