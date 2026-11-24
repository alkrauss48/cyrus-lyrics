//
//  PillButtonStyle.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 11/24/26.
//

import SwiftUI

extension Color {
    static let brand = Color("Primary")
    static let spotify = Color(red: 37 / 255, green: 211 / 255, blue: 78 / 255)
}

/// A full-width, capsule-shaped button for a screen's main action.
struct PillButtonStyle: ButtonStyle {
    var color: Color = .brand

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(isEnabled ? color : .gray, in: .capsule)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle {
        PillButtonStyle()
    }

    static func pill(_ color: Color) -> PillButtonStyle {
        PillButtonStyle(color: color)
    }
}

#Preview {
    VStack {
        Button("Add Songs") {}
            .buttonStyle(.pill)
        Button("Open in Spotify") {}
            .buttonStyle(.pill(.spotify))
        Button("Disabled") {}
            .buttonStyle(.pill)
            .disabled(true)
    }
    .padding()
}
