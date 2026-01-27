//
//  MVPDGridView.swift
//  ViewliftPlayerSampleApp
//
//  Created by rakeshkrsharma@viewlift.com on 17/10/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import SwiftUI
import VLAuthenticationFramework

// MARK: - SwiftUI Grid View with Dismiss
struct MVPDGridView: View {
    let mvpdList: [AdobeMvpd]
    var onSelection: ((AdobeMvpd) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(mvpdList) { mvpd in
                    MVPDCell(mvpd: mvpd) {
                        handleSelection(mvpd)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Select Provider")
    }
    
    private func handleSelection(_ mvpd: AdobeMvpd) {
        print("Selected: \(mvpd.displayName)")
        onSelection?(mvpd)
        dismiss()
    }
}

// MARK: - Updated Grid Cell
struct MVPDCell: View {
    let mvpd: AdobeMvpd
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: mvpd.logoURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 60)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .frame(height: 60)
                @unknown default:
                    EmptyView()
                }
            }
            
            Text(mvpd.displayName)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 30)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}
