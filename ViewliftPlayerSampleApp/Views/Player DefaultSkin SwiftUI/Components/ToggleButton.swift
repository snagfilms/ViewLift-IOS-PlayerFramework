//
//  ToggleButton.swift
//  playerKinUI
//
//  Created by Japneet Singh on 02/08/25.
//

import SwiftUI

struct ToggleButton: View {
    let isOn: Bool
    let onIcon: String
    let offIcon: String
    let labelOn: String
    let labelOff: String
    let iconScale: CGFloat
    let action: () -> Void

    var body: some View {
        PlayerControlButton(
            systemName: isOn ? onIcon : offIcon,
            label: isOn ? labelOn : labelOff,
            iconScale: iconScale,
            action: action
        )
    }
}
