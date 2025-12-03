//
//  EditProfileView.swift
//  Swipop
//

import SwiftUI

struct EditProfileView: View {
    
    let profile: Profile?
    
    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    @State private var displayName: String
    @State private var bio: String
    @State private var links: [ProfileLink]
    @State private var isSaving = false
    @FocusState private var focusedField: Field?
    
    private enum Field { case displayName, username, bio }
    
    private let userService = UserService.shared
    
    init(profile: Profile?) {
        self.profile = profile
        _username = State(initialValue: profile?.username ?? "")
        _displayName = State(initialValue: profile?.displayName ?? "")
        _bio = State(initialValue: profile?.bio ?? "")
        _links = State(initialValue: profile?.links ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Avatar Section
                Section {
                    avatarView
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
                
                // Profile Section
                Section("Profile") {
                    fieldRow(label: "Display Name") {
                        TextField("Your name", text: $displayName)
                            .focused($focusedField, equals: .displayName)
                    }
                    
                    fieldRow(label: "Username") {
                        TextField("username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .username)
                    }
                }
                
                // Bio Section
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bio")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $bio)
                            .font(.system(size: 16))
                            .frame(minHeight: 60)
                            .scrollContentBackground(.hidden)
                            .focused($focusedField, equals: .bio)
                    }
                }
                
                // Links Section
                Section {
                    ForEach($links) { $link in
                        LinkEditRow(link: $link, onDelete: {
                            links.removeAll { $0.id == link.id }
                        })
                    }
                    
                    Button {
                        links.append(ProfileLink())
                    } label: {
                        Label("Add Link", systemImage: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.brand)
                    }
                } header: {
                    Text("Links")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { focusedField = nil }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Field Row
    
    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            content()
                .font(.system(size: 16))
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Avatar View
    
    private var avatarView: some View {
        HStack {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text((displayName.isEmpty ? "U" : displayName).prefix(1).uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    )
                
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 16))
                    )
            }
            Spacer()
        }
    }
    
    // MARK: - Save
    
    private func save() async {
        guard var updated = profile else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        updated.username = username.isEmpty ? nil : username
        updated.displayName = displayName.isEmpty ? nil : displayName
        updated.bio = bio.isEmpty ? nil : bio
        updated.links = links.filter { !$0.title.isEmpty && !$0.url.isEmpty }
        
        do {
            _ = try await userService.updateProfile(updated)
            await CurrentUserProfile.shared.refresh()
            dismiss()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
}

// MARK: - Link Edit Row

private struct LinkEditRow: View {
    @Binding var link: ProfileLink
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Title")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)
                
                TextField("e.g. GitHub", text: $link.title)
                    .font(.system(size: 16))
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                Text("URL")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)
                
                TextField("https://", text: $link.url)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }
        }
    }
}

#Preview {
    EditProfileView(profile: .sample)
}
