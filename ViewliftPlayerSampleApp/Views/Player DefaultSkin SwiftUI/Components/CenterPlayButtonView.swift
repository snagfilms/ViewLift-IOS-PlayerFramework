//
//  CenterPlayButtonView.swift
//  playerKinUI
//
//  Created by Japneet Singh on 02/08/25.
//

import SwiftUI

struct CenterPlayButtonView: View {
    let isPlaying: Bool
    let action: () -> Void
    let size: CGFloat

    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: size))
                .foregroundColor(.white)
        }
    }
}
