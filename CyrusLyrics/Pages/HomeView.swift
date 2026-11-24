//
//  HomeView.swift
//  CyrusLyrics
//
//  Created by Aaron Krauss on 2/7/22.
//

import AuthenticationServices
import OSLog
import SwiftUI

struct HomeView: View {
    @Environment(StateManager.self) private var stateManager
    @Environment(\.openURL) private var openURL
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @State private var isShowingCreateList = false
    @State private var fileToDelete: APIFile?

    var body: some View {
        NavigationStack {
            List {
                if !stateManager.isConnected {
                    Label("You Are Offline", systemImage: "wifi.slash")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .listRowBackground(Color.red)
                }

                if !stateManager.userFiles.isEmpty {
                    Section("Your Lists") {
                        ForEach(stateManager.userFiles) { file in
                            fileRow(file)
                                .swipeActions {
                                    if GoogleSheetsApp.isInstalled {
                                        Button("Edit", systemImage: "square.and.pencil") {
                                            open(file.sheetsAppURL)
                                        }
                                        .tint(.blue)
                                    } else {
                                        viewButton(for: file)
                                    }

                                    Button("Delete", systemImage: "trash.fill", role: .destructive) {
                                        fileToDelete = file
                                    }
                                    .disabled(!stateManager.isConnected)
                                }
                        }
                    }
                }

                if !stateManager.defaultFiles.isEmpty {
                    Section("Preloaded Lists") {
                        ForEach(stateManager.defaultFiles) { file in
                            fileRow(file)
                                .swipeActions {
                                    viewButton(for: file)
                                }
                        }
                    }
                }

                Section {
                    if stateManager.isLoggedIn {
                        Button {
                            isShowingCreateList = true
                        } label: {
                            HStack {
                                Text("Create List")

                                if stateManager.isCreatingSheet {
                                    Spacer()
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(!stateManager.isConnected || stateManager.isCreatingSheet)

                        Button("Log Out") {
                            stateManager.signOut()
                        }
                    } else {
                        Button("Log In") {
                            Task {
                                await signIn()
                            }
                        }
                        .disabled(!stateManager.isConnected)
                    }
                } header: {
                    Text("Actions")
                } footer: {
                    HStack(spacing: 4) {
                        Text("Powered by")
                        Image("google-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .accessibilityLabel("Google")
                    }
                }
                .tint(.primary)

                Section("About") {
                    NavigationLink("How It Works") {
                        HowItWorksView()
                    }
                }
            }
            .navigationTitle("CyrusLyrics")
            .refreshable {
                await stateManager.refreshLists()
            }
            .confirmationDialog(
                "Are you sure you want to delete this list?",
                isPresented: isConfirmingDelete,
                presenting: fileToDelete
            ) { file in
                Button("Send List to Trash", role: .destructive) {
                    Task {
                        await stateManager.delete(file)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCreateList) {
            CreateListView()
        }
    }

    private func fileRow(_ file: APIFile) -> some View {
        NavigationLink {
            CategoryList(file: file)
        } label: {
            HStack {
                Text(file.name)

                if stateManager.deletingFile == file {
                    Spacer()
                    ProgressView()
                }
            }
        }
        // Offline, only the active list has cached songs
        .disabled(!stateManager.isConnected && stateManager.activeFile != file)
    }

    private func viewButton(for file: APIFile) -> some View {
        Button("View", systemImage: "eye.fill") {
            open(file.webURL)
        }
        .tint(.yellow)
        .disabled(!stateManager.isConnected)
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding {
            fileToDelete != nil
        } set: { isPresented in
            if !isPresented {
                fileToDelete = nil
            }
        }
    }

    private func open(_ url: URL?) {
        if let url {
            openURL(url)
        }
    }

    private func signIn() async {
        do {
            let callbackURL = try await webAuthenticationSession.authenticate(
                using: stateManager.signInURL,
                callbackURLScheme: "cyruslyrics",
                preferredBrowserSession: .shared
            )

            await stateManager.signIn(callbackURL: callbackURL)
        } catch ASWebAuthenticationSessionError.canceledLogin {
            // The user closed the sign-in sheet
        } catch {
            Logger.auth.error("Sign-in failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

#Preview {
    HomeView()
        .environment(StateManager.preview())
}
