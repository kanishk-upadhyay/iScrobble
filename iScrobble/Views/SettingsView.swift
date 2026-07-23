import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow
    @Binding var page: PopoverPage

    @State private var showingSignOut = false

    private var storage: StorageManager { appState.storage }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    page = .main
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .pointerCursor()
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            Form {
                Section("Scrobbling") {
                    Toggle(isOn: Binding(
                        get: { storage.scrobblingEnabled },
                        set: { storage.scrobblingEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable scrobbling")
                            Text("Automatically scrobble tracks to Last.fm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Launch") {
                    Toggle(isOn: Binding(
                        get: { SMAppService.mainApp.status == .enabled },
                        set: { enabled in
                            do {
                                if enabled {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                                storage.launchAtLogin = enabled
                            } catch {
                                print("[Settings] Failed to toggle launch at login: \(error)")
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Launch at login")
                            Text("Automatically start iScrobble when you log in")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Account") {
                    if storage.isAuthenticated {
                        if let username = storage.username {
                            LabeledContent("Last.fm User", value: username)
                        }
                        Button("Sign Out", role: .destructive) {
                            showingSignOut = true
                        }
                    } else {
                        Text("Not signed in")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("API Credentials") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Last.fm API Key")
                            if storage.hasValidAPICredentials {
                                Text("Configured")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Not configured")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                        Button(storage.hasValidAPICredentials ? "Reconfigure" : "Configure") {
                            NSApp.setActivationPolicy(.regular)
                            NSApp.activate(ignoringOtherApps: true)
                            openWindow(id: "api-credentials")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)
                        .pointerCursor()
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: version)
                    HStack(spacing: 4) {
                        Text("Created by")
                            .foregroundStyle(.secondary)
                        Button("HeXif") {
                            openURL(URL(string: "https://hexif.vercel.app")!)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)
                        .pointerCursor()
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 380)
        .confirmationDialog(
            "Sign out of Last.fm?",
            isPresented: $showingSignOut,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                storage.sessionKey = nil
                storage.username = nil
                page = .main
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("iScrobble will stop scrobbling until you sign in again.")
        }
    }
}
