//
//  CommentSheet.swift
//  Swipop
//

import SwiftUI
import Auth

struct CommentSheet: View {
    
    let work: Work
    @Binding var showLogin: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isLoading = true
    @State private var isSending = false
    
    private let auth = AuthService.shared
    private let service = CommentService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isLoading {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else if comments.isEmpty {
                        emptyState
                    } else {
                        commentList
                    }
                    
                    Divider().background(Color.white.opacity(0.2))
                    commentInput
                }
            }
            .navigationTitle("\(work.commentCount) Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.title2)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.black)
        .task {
            await loadComments()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            Text("No comments yet")
                .foregroundColor(.white.opacity(0.5))
            Text("Be the first to comment!")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
            Spacer()
        }
    }
    
    // MARK: - Comment List
    
    private var commentList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(comments) { comment in
                    CommentRow(comment: comment, onDelete: {
                        await deleteComment(comment)
                    })
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Comment Input
    
    private var commentInput: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "a855f7"))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(auth.currentUser?.email?.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            TextField("Add a comment...", text: $newComment)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .disabled(!auth.isAuthenticated)
            
            Button {
                Task { await sendComment() }
            } label: {
                if isSending {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(newComment.isEmpty ? .white.opacity(0.3) : Color(hex: "a855f7"))
                }
            }
            .disabled(newComment.isEmpty || isSending)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .onTapGesture {
            if !auth.isAuthenticated {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showLogin = true
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadComments() async {
        do {
            let result = try await service.fetchComments(workId: work.id)
            await MainActor.run {
                comments = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("Failed to load comments: \(error)")
        }
    }
    
    private func sendComment() async {
        guard let userId = auth.currentUser?.id else {
            showLogin = true
            return
        }
        
        let content = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        isSending = true
        
        do {
            let comment = try await service.createComment(
                workId: work.id,
                userId: userId,
                content: content
            )
            await MainActor.run {
                comments.insert(comment, at: 0)
                newComment = ""
                isSending = false
            }
        } catch {
            await MainActor.run {
                isSending = false
            }
            print("Failed to send comment: \(error)")
        }
    }
    
    private func deleteComment(_ comment: Comment) async {
        do {
            try await service.deleteComment(id: comment.id)
            await MainActor.run {
                comments.removeAll { $0.id == comment.id }
            }
        } catch {
            print("Failed to delete comment: \(error)")
        }
    }
}

// MARK: - Comment Row

private struct CommentRow: View {
    
    let comment: Comment
    let onDelete: () async -> Void
    
    private let auth = AuthService.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: "a855f7"))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(comment.user?.username?.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(comment.user?.username ?? "user")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(timeAgo(comment.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Spacer()
                    
                    // Delete button (only for own comments)
                    if comment.userId == auth.currentUser?.id {
                        Button {
                            Task { await onDelete() }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                
                Text(comment.content)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                
                if let replyCount = comment.replyCount, replyCount > 0 {
                    Text("\(replyCount) replies")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "a855f7"))
                        .padding(.top, 4)
                }
            }
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        if seconds < 86400 { return "\(seconds / 3600)h" }
        if seconds < 604800 { return "\(seconds / 86400)d" }
        
        return "\(seconds / 604800)w"
    }
}

#Preview {
    CommentSheet(work: .sample, showLogin: .constant(false))
}

