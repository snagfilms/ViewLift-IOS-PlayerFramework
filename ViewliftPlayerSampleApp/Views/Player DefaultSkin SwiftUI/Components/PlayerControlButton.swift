//
//  PlayerControlButton.swift
//  playerKinUI
//
//  Created by Japneet Singh on 02/08/25.
//

import SwiftUI

struct PlayerControlButton: View {
    let systemName: String
    let label: String?
    let iconScale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 18 * iconScale))
                    .foregroundColor(.white)
                if let label {
                    Text(label)
                        .font(.system(size: 12 * iconScale))
                        .foregroundColor(.white)
                }
            }
        }
    }
}
