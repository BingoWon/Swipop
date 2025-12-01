//
//  SearchView.swift
//  Swipop
//

import SwiftUI

struct SearchView: View {
    
    @Binding var searchText: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Search works and creators")
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    Text("Results for: \(searchText)")
                        .foregroundColor(.white)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Works, creators...")
        }
    }
}

#Preview {
    SearchView(searchText: .constant(""))
        .preferredColorScheme(.dark)
}

