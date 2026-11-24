//
//  CreateListView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import SwiftUI

struct CreateListView: View {
    @Environment(StateManager.self) private var stateManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = "My CyrusLyrics Songs"
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("List Name", text: $name)
                    .modifier(TextFieldClearButton(text: $name))
                    .focused($isNameFocused)
                    .submitLabel(.go)
                    .onSubmit(create)
            }
            .navigationTitle("Create List")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .task {
                // Focusing right away doesn't work while the sheet animates in
                try? await Task.sleep(for: .milliseconds(550))
                isNameFocused = true
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func create() {
        guard !trimmedName.isEmpty else {
            return
        }

        let title = trimmedName

        Task {
            await stateManager.createSheet(title: title)
        }

        dismiss()
    }
}

#Preview {
    CreateListView()
        .environment(StateManager.preview())
}
