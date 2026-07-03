//
//  LiveMomentsTabView.swift
//  ViewliftPlayerSampleApp
//
//  Created by Amit Pandey on 27/05/26.
//  Copyright © 2026 Viewlift. All rights reserved.
//
import SwiftUI

// MARK: - Live Moments
struct LiveMomentsTabItem: Identifiable {
    // Stable id so per-second refreshes preserve tab selection / scroll state.
    var id: String { title }
    let title: String
    let moments: [LiveMomentItem]
}

struct LiveMomentItem: Identifiable {
    // Stable id (the cue point's own startTime) so per-second refreshes keep list
    // identity and don't reset scroll position while the DVR window slides.
    var id: Double { seekSeconds }
    let thumbnailAssetName: String
    let title: String
    let startTimeLabel: String
    let seekSeconds: Double
}

/// Reference-type backing store for the Live Moments list. The host mutates `tabs`
/// only when a chapter enters or leaves the DVR window, so SwiftUI diffs the
/// `ForEach` by stable id and inserts/removes just the affected row instead of the
/// list being rebuilt (which happened when the whole `rootView` was reassigned).
final class LiveMomentsModel: ObservableObject {
    @Published var tabs: [LiveMomentsTabItem]

    init(tabs: [LiveMomentsTabItem]) {
        self.tabs = tabs
    }
}

struct LiveMomentsTabsView: View {
    @ObservedObject var model: LiveMomentsModel
    var onMomentTap: (Double) -> Void

    private var tabs: [LiveMomentsTabItem] { model.tabs }

    @State private var selectedTabId: String?

    private let columns = [GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tabs) { tab in
                        Button {
                            selectedTabId = tab.id
                        } label: {
                            Text(tab.title)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundColor(selectedTabId == tab.id ? .white : .primary)
                                .background(selectedTabId == tab.id ? Color.blue : Color.gray.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(selectedMoments) { moment in
                        Button {
                            onMomentTap(moment.seekSeconds)
                        } label: {
                            HStack(spacing: 12) {
                                Image(moment.thumbnailAssetName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 60)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(moment.title)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)

                                    Text("Start \(moment.startTimeLabel)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            selectedTabId = selectedTabId ?? tabs.first?.id
        }
    }

    private var selectedMoments: [LiveMomentItem] {
        guard let selectedTabId,
              let selectedTab = tabs.first(where: { $0.id == selectedTabId }) else {
            return tabs.first?.moments ?? []
        }
        return selectedTab.moments
    }
}
