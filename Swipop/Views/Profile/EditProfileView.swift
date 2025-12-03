//
//  EditProfileView.swift
//  Swipop
//

import SwiftUI

struct EditProfileView: View {
    
    let profile: Profile?
    
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var isSaving = false
    
    private let userService = UserService.shared
    
    init(profile: Profile?) {
        self.profile = profile
        _username = State(initialValue: profile?.username ?? "")
        _displayName = State(initialValue: profile?.displayName ?? "")
        _bio = State(initialValue: profile?.bio ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Avatar
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.brand)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(displayName.prefix(1).uppercased())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(.white)
                                )
                            
                            Circle()
                                .fill(Color.appBackground.opacity(0.5))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundStyle(.white)
                                )
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Profile") {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Display Name", text: $displayName)
                    
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
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
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func save() async {
        guard var updated = profile else { return }
        
        isSaving = true
        
        updated.username = username.isEmpty ? nil : username
        updated.displayName = displayName.isEmpty ? nil : displayName
        updated.bio = bio.isEmpty ? nil : bio
        
        do {
            _ = try await userService.updateProfile(updated)
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Failed to save profile: \(error)")
        }
        
        isSaving = false
    }
}

#Preview {
    EditProfileView(profile: .sample)
}
