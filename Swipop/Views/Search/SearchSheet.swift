//
//  SearchSheet.swift
//  Swipop
//
//  Search presented as a sheet from toolbar
//

import SwiftUI

struct SearchSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if searchText.isEmpty {
                    // Trending / Suggestions
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            trendingSection
                            suggestedCreatorsSection
                        }
                        .padding(16)
                    }
                } else {
                    // Search Results
                    searchResults
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Works, creators...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.black)
    }
    
    // MARK: - Trending Section
    
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Trending", systemImage: "flame.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(trendingTags, id: \.self) { tag in
                Button {
                    searchText = tag
                } label: {
                    HStack {
                        Text("#\(tag)")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "a855f7"))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Suggested Creators
    
    private var suggestedCreatorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Suggested Creators", systemImage: "person.2.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(suggestedCreators, id: \.self) { creator in
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "a855f7"))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(creator.prefix(1).uppercased())
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            Text("@\(creator)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        .frame(width: 80)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Results
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text("Results for \"\(searchText)\"")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                // Placeholder results
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Work Title")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                            Text("@creator")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
    }
    
    // MARK: - Sample Data
    
    private var trendingTags: [String] {
        ["animation", "3d", "particles", "gradient", "interactive", "generative"]
    }
    
    private var suggestedCreators: [String] {
        ["alice", "bob", "charlie", "diana", "eve"]
    }
}

#Preview {
    SearchSheet()
        .preferredColorScheme(.dark)
}

