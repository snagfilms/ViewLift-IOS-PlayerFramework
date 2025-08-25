//
//  DeviceRotationViewModifier.swift
//  playerKinUI
//
//  Created by Japneet Singh on 02/08/25.
//

import SwiftUI

// MARK: - Device Orientation Detection
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                debugPrint("Player orientation: \(String(describing: DeviceOrientationType(rawValue: UIDevice.current.orientation.rawValue)))")
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}


private enum DeviceOrientationType : Int {

    case unknown = 0

    case portrait = 1

    case portraitUpsideDown = 2

    case landscapeLeft = 3

    case landscapeRight = 4

    case faceUp = 5

    case faceDown = 6
}
