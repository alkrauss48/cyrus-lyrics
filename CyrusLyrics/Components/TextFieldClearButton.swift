//
//  TextFieldClearButton.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct TextFieldClearButton: ViewModifier {
    @Binding var text: String

    func body(content: Content) -> some View {
        HStack {
            content

            if !text.isEmpty {
                Button("Clear", systemImage: "delete.left") {
                    text = ""
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.gray)
                .buttonStyle(.borderless)
            }
        }
    }
}

#Preview {
    @Previewable @State var text = "Some text"

    Form {
        TextField("Name", text: $text)
            .modifier(TextFieldClearButton(text: $text))
    }
}
