//
//  PlayerControlsHostingView.swift
//  ViewliftPlayerSampleApp
//
//  Created by Japneet Singh on 14/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import SwiftUI
import VLPlayerLib

//CustomSkin Wrapper
class PlayerControlsHostingView: UIView, CustomPlayerSkinProtocol {
    private let hostingController: UIHostingController<PlayerControlsView>
    private var playerViewModel: PlayerControlsViewModel

    init(viewModel: PlayerControlsViewModel) {
        self.playerViewModel = viewModel
        self.hostingController = UIHostingController(rootView: PlayerControlsView(viewModel: viewModel))
        super.init(frame: .zero)
        
        let hostedView = hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear
        addSubview(hostedView)
        
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: topAnchor),
            hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostedView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - CustomPlayerSkinProtocol
    func shouldHideControlsOnTap() -> Bool {
        return true
    }

    var isAdOnMainView: Bool { false }
    var adRunningOnInternalPlayer: Bool = false

    func muteUnmuteAdButtonTapped(isTrue: Bool) {
        playerViewModel.toggleMute(isMuted: !isTrue)
    }

    func fullScreenAdButtonTapped(isFullscreen: Bool) {
        playerViewModel.toggleFullScreen(isFullScreen: isFullscreen)
    }

    func updatePlayButton() {
    }

}
