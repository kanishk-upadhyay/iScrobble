//
//  iScrobbleWidgetControl.swift
//  iScrobbleWidget
//

import AppIntents
import SwiftUI
import WidgetKit

struct iScrobbleWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.hexif.iScrobble.iScrobbleWidget",
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Scrobbling",
                isOn: value,
                action: ToggleScrobblingIntent()
            ) { isOn in
                Label(isOn ? "Scrobbling On" : "Scrobbling Off", systemImage: isOn ? "music.note" : "music.note.slash")
            }
        }
        .displayName("iScrobble")
        .description("Toggle scrobbling from Control Center.")
    }
}

extension iScrobbleWidgetControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }

        func currentValue() async throws -> Bool {
            // Shared UserDefaults is the only bridge to the main app
            let defaults = UserDefaults(suiteName: SharedDefaults.appGroupID)
            return defaults?.object(forKey: SharedDefaults.scrobblingEnabled) as? Bool ?? true
        }
    }
}

struct ToggleScrobblingIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Toggle scrobbling"

    @Parameter(title: "Scrobbling enabled")
    var value: Bool

    func perform() async throws -> some IntentResult {
        if let defaults = UserDefaults(suiteName: SharedDefaults.appGroupID) {
            defaults.set(value, forKey: SharedDefaults.scrobblingEnabled)
        }
        return .result()
    }
}
