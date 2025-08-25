//
//  CastUIButton.swift
//  VLPlayer
//
//  Created by Japneet Singh on 04/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//


import SwiftUI
import UIKit

struct CastUIButton: UIViewRepresentable {
    let frame: CGRect
    let action: (UIButton) -> Void
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = frame
        
        var castImage = "ChromeCast_Square_Off"
//        if CastPopOverView.shared.isConnected(){
//            castImage = "ChromeCast_Square_On"
//        }
        
        let image = UIImage(
            named: castImage,
            in: Bundle(identifier: "com.viewlift.vlplayer"),
            compatibleWith: nil
        )
        button.setImage(image, for: .normal)

        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.imageEdgeInsets = .zero

//        button.imageView?.tintColor = (playerControlsColor?.iconColor ?? "ffffff").hexStringToUIColor()
        button.tintColor = .white
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTapButton), for: .touchUpInside)

        return button
    }


    func updateUIView(_ uiView: UIButton, context: Context) {
        // no-op for now
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        let action: (UIButton) -> Void

        init(action: @escaping (UIButton) -> Void) {
            self.action = action
        }

        @objc func didTapButton(sender: UIButton) {
            action(sender)
        }
    }
}
