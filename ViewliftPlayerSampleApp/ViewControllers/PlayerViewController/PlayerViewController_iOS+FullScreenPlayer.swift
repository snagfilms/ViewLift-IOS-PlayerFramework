//
//  PlayerViewController_iOS+FullScreenPlayer.swift
//  ViewliftPlayerSampleApp
//
//  Created by vikassachan@viewlift.com on 12/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

extension PlayerViewController_iOS {
    
    func onFullScreenChange(currentTime: Double, isFullScreen: Bool, playerTag: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.isFullScreen = isFullScreen
        isFullscreen = isFullScreen
        allowLandscapeRotation = isFullScreen // only allow rotation when fullscreen
        videoPlayerCustomView?.viewModel?.isLandscape = isFullScreen
        if isFullScreen {
            // Activate fullscreen constraints
            NSLayoutConstraint.deactivate(normalConstraints)
            NSLayoutConstraint.activate(fullscreenConstraints)
            setLiveMomentsVisibility(isHidden: true)
            
            // Force landscape orientation
            goFullScreenLandscape()
            
        } else {
            // Activate normal constraints
            NSLayoutConstraint.deactivate(fullscreenConstraints)
            NSLayoutConstraint.activate(normalConstraints)
            setLiveMomentsVisibility(isHidden: false)
            
            // Return to portrait if device is portrait
            goPortraitIfNeeded()
        }
    }
    
    func goFullScreenLandscape() {
        guard let windowScene = view.window?.windowScene else { return }
        
        let currentUIOrientation = windowScene.interfaceOrientation
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if #available(iOS 16.0, *) {
                let targetMask: UIInterfaceOrientationMask
                
                if currentUIOrientation.isLandscape {
                    // Keep current landscape side
                    targetMask = (currentUIOrientation == .landscapeLeft) ? .landscapeLeft : .landscapeRight
                } else {
                    // Portrait → use physical device orientation if possible
                    let deviceOrientation = UIDevice.current.orientation
                    if deviceOrientation == .landscapeLeft {
                        targetMask = .landscapeLeft
                    } else if deviceOrientation == .landscapeRight {
                        targetMask = .landscapeRight
                    } else {
                        // Fallback to RIGHT if unknown/faceUp
                        targetMask = .landscapeRight
                    }
                }
                
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: targetMask))
                
            } else {
                let orientation: UIInterfaceOrientation = currentUIOrientation.isLandscape
                ? currentUIOrientation
                : .landscapeRight
                UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
                UINavigationController.attemptRotationToDeviceOrientation()
            }
            
        } else {
            // iPhone
            if #available(iOS 16.0, *) {
                let targetMask: UIInterfaceOrientationMask
                if currentUIOrientation.isLandscape {
                    targetMask = (currentUIOrientation == .landscapeLeft) ? .landscapeLeft : .landscapeRight
                } else {
                    let deviceOrientation = UIDevice.current.orientation
                    if deviceOrientation == .landscapeLeft {
                        targetMask = .landscapeLeft
                    } else if deviceOrientation == .landscapeRight {
                        targetMask = .landscapeRight
                    } else {
                        targetMask = .landscapeRight
                    }
                }
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: targetMask))
            } else {
                let orientation: UIInterfaceOrientation = currentUIOrientation.isLandscape
                ? currentUIOrientation
                : .landscapeRight
                UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
                UINavigationController.attemptRotationToDeviceOrientation()
            }
        }
    }
    
    func goPortraitIfNeeded() {
        guard let windowScene = view.window?.windowScene else { return }
        
        let currentOrientation = windowScene.interfaceOrientation
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad → if already landscape, don't change
            if currentOrientation.isLandscape {
                return
            }
            // Only force portrait if iPad is actually in portrait mode change scenario (rare)
            if #available(iOS 16.0, *) {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UINavigationController.attemptRotationToDeviceOrientation()
            }
        } else {
            // iPhone → always go to portrait when needed
            guard !currentOrientation.isPortrait else { return }
            
            if #available(iOS 16.0, *) {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UINavigationController.attemptRotationToDeviceOrientation()
            }
        }
    }

}
