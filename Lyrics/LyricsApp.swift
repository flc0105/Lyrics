//
//  LyricsApp.swift
//  Lyrics
//
//  Created by Fang Liangchen on 2023/12/19.
//

import Foundation
import SwiftUI
import HotKey


/// A shared instance for managing user interface preferences.
class UIPreferences: ObservableObject {
    /// The shared instance of `UIPreferences`.
    static let shared = UIPreferences()
    
    /// The cover image for the background.
    @Published var coverImage: NSImage?
    
    /// The playback progress time interval.
    @Published var playbackProgress: TimeInterval = 0
    
    /// A boolean indicating whether the cover image is visible.
    @Published var isCoverImageVisible: Bool = isCoverImageVisibleConfig()
    
    /// A boolean indicating whether the playback progress is visible.
    @Published var isPlaybackProgressVisible: Bool = isPlaybackProgressVisibleConfig()
    
    /// A boolean indicating whether the window is sticky.
    @Published var isWindowSticky: Bool = false
    
}


/// AppDelegate class responsible for managing the application's lifecycle.
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// The main window of the application.
    var window: NSWindow!
    
    /// Subwindow dedicated to searching for lyrics.
    var subwindow: NSWindow!
    
    /// Called when the application finishes launching.
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        initializeLyrics(withDefault: [
            LyricInfo(id: 0, text: "Not playing.", isCurrent: false, playbackTime: 0, isTranslation: false),
        ])
        
        registerNotifications()
        
        // Create and configure the main window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        
        // Create a visual effect view for the window
        let visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.material = .dark
        
        // Create a hosting view for the SwiftUI content
        let hostingView = NSHostingView(rootView: LyricsView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(hostingView)
        
        // Set up constraints for the hosting view
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])
        
        // Set the content view of the window to the visual effect view
        window.contentView = visualEffectView
        
        // Make the window titlebar transparent.
        window.titlebarAppearsTransparent = true
        
        // Hide the zoom button in the top-left corner of the window.
        window.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isHidden = true
        
        // Hide the minimize button in the top-left corner of the window.
        window.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)!.isHidden = true
        
        // Center the window on the screen.
        window.center()
        
        // Allow moving the window by interacting with the background.
        window.isMovableByWindowBackground = true
        
        // Set a unique name for saving the window's frame position and size.
        window.setFrameAutosaveName("LyricsWindow")
        
        // Make the window key and order it to the front.
        window.makeKeyAndOrderFront(nil)
        
        // Remove the resizable style mask to disable resizing the window.
        window.styleMask.remove(.resizable)
    }
    
    
    /// Determines whether the application should terminate after the last window is closed.
    ///
    /// - Parameter sender: The NSApplication instance.
    /// - Returns: `true` if the application should terminate after the last window is closed; otherwise, `false`.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    
    /// Toggles the stickiness of the main window.
    /// - Parameter sender: The object that triggered the action.
    @objc func toggleWindowSticky(_ sender: Any?) {
        if let window = NSApplication.shared.keyWindow {
            window.level = (window.level == .floating) ? .normal : .floating
            UIPreferences.shared.isWindowSticky = (window.level == .floating)
        }
    }
    
    /// Shows the subwindow for searching lyrics if it is not already visible.
    /// - Parameter sender: The object that triggered the action (e.g., a menu item).
    @objc func showSubwindow(_ sender: Any?) {
        // Check if the subwindow is already visible
        guard subwindow == nil else {
            return
        }
        
        // Create and configure the subwindow
        subwindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        
        // Set up the content view with the SubWindowView
        let subwindowView = LyricsSearchView() {
            self.closeSubwindow()
        }
        
        // Set the content view of the subwindow
        subwindow.contentView = NSHostingView(rootView: subwindowView)
        
        // Show the subwindow
        subwindow.center()
        
        subwindow.makeKeyAndOrderFront(nil)
    }
    
    
    /// Closes the subwindow used for searching lyrics.
    func closeSubwindow() {
        subwindow = nil
    }
}


/// Adjusts the start time to make the lyrics display 1 second faster.
func handle1SecondFaster() {
    startTime -= 1
}


/// Adjusts the start time to make the lyrics display 1 second slower.
func handle1SecondSlower() {
    startTime += 1
}


/// Handles manual input for calibration.
func handleManualCalibration() {
    showInputAlert(
        title: "Manual Calibration",
        message: "Enter the time adjustment value (e.g., +0.5 or -0.5). Positive values speed up the playback, and negative values slow down the playback.",
        defaultValue: "-1.5",
        onFirstButtonTap: { input in
            guard let adjustment = TimeInterval(input) else {
                showAlert(title: "Manual Calibration", message: "Please enter a valid numeric value.")
                return
            }
            startTime -= adjustment
            showAlert(title: "Manual Calibration", message: "Adjusted by \(adjustment) seconds.")
        }
    )
}


/// Handles configuring the player.
func handleConfigurePlayer() {
    let playerNameConfig = getPlayerNameConfig()
    showInputAlert(title: "Configure Player",
                   message: "Enter the app bundle identifier of the player used to register for notifications.",
                   defaultValue: playerNameConfig,
                   onFirstButtonTap: { inputText in
        UserDefaults.standard.set(inputText, forKey: "PlayerPackageName")
        showAlert(title: "Settings Saved", message: "Changes will take effect after restarting the application.", firstButtonTitle: "Restart", onFirstButtonTap: {
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                let path = "/usr/bin/open"
                let arguments = ["-b", bundleIdentifier]
                Process.launchedProcess(launchPath: path, arguments: arguments)
            }
            NSApp.terminate(nil)
        }, showCancelButton: true)
    })
}


/// Handles configuring the lyrics folder.
func handleConfigureLyricsFolder() {
    let lyricsFolderPathConfig = getLyricsFolderPathConfig()
    showFolderPicker(message: "Choose the lyrics folder, the current path is: \(lyricsFolderPathConfig)", defaultFolderPath: lyricsFolderPathConfig) { selectedFolderPath in
        if var folderPath = selectedFolderPath {
            if !folderPath.hasSuffix("/") {
                folderPath.append("/")
            }
            UserDefaults.standard.set(folderPath, forKey: "LyricsFolder")
            showAlert(title: "Settings Saved", message: "Lyrics folder has been successfully set: \(getLyricsFolderPathConfig())")
        }
    }
}

/// Opens the lyrics search window.
func handleSearchLyrics() {
    NSApp.sendAction(#selector(AppDelegate.showSubwindow(_:)), to: nil, from: nil)
}


/// Handles toggling sticky window.
func handleToggleSticky(isEnabled: Bool) {
    UIPreferences.shared.isWindowSticky = isEnabled
    NSApp.sendAction(#selector(AppDelegate.toggleWindowSticky(_:)), to: nil, from: nil)
    debugPrint("isWindowSticky=\(UIPreferences.shared.isWindowSticky)")
}


/// Handles toggling show album cover.
func handleToggleShowAlbumCover(isEnabled: Bool) {
    UIPreferences.shared.isCoverImageVisible = isEnabled
    debugPrint("isCoverImageVisible=\(UIPreferences.shared.isCoverImageVisible)")
    if (!UIPreferences.shared.isCoverImageVisible) {
        UIPreferences.shared.coverImage = nil
        UserDefaults.standard.set(false, forKey: "IsCoverImageVisible")
    } else {
        updateAlbumCover()
        UserDefaults.standard.set(true, forKey: "IsCoverImageVisible")
    }
}

/// Handles toggling show playback progress.
func handleToggleShowPlaybackProgress(isEnabled: Bool) {
    UIPreferences.shared.isPlaybackProgressVisible = isEnabled
    debugPrint("isPlaybackProgressVisible=\(UIPreferences.shared.isPlaybackProgressVisible)")
    UserDefaults.standard.set(UIPreferences.shared.isPlaybackProgressVisible, forKey: "IsPlaybackProgressVisible")
}


// The main entry point for the LyricsApp.
@main
struct LyricsApp: App {
    
    // Define a hotkey for the application
    let hotKey = HotKey(key: .l, modifiers: [.control], keyDownHandler: {NSApp.activate(ignoringOtherApps: true)})
    
    // The app delegate for managing the application's lifecycle.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @ObservedObject private var uiPreferences = UIPreferences.shared
    
    // The body of the app scene.
    var body: some Scene {
        // Settings scene
        Settings {
            EmptyView()
        }
        .commands {
            CommandMenu("Display") {
                Toggle("Toggle Sticky", isOn: Binding<Bool>(
                    get: {
                        return uiPreferences.isWindowSticky
                    },
                    set: { isEnabled in
                        handleToggleSticky(isEnabled: isEnabled)
                    }
                ))
                Toggle("Show Album Cover", isOn: Binding<Bool>(
                    get: {
                        return uiPreferences.isCoverImageVisible
                    },
                    set: { isEnabled in
                        handleToggleShowAlbumCover(isEnabled: isEnabled)
                    }
                ))
                Toggle("Show Playback Progress", isOn: Binding<Bool>(
                    get: {
                        return uiPreferences.isPlaybackProgressVisible
                    },
                    set: { isEnabled in
                        handleToggleShowPlaybackProgress(isEnabled: isEnabled)
                    }
                ))
            }
            CommandMenu("Playback") {
                Button("1 Second Faster") { handle1SecondFaster() }.keyboardShortcut("+")
                Button("1 Second Slower") { handle1SecondSlower() }.keyboardShortcut("-")
                Button("Manual Calibration") { handleManualCalibration() }
            }
            CommandMenu("Settings") {
                Button("Configure Player") { handleConfigurePlayer() }
                Button("Configure Lyrics Folder") { handleConfigureLyricsFolder() }
            }
            CommandMenu("Utilities") {
                Button("Search Lyrics") { handleSearchLyrics() }.keyboardShortcut("s")
            }
        }
    }
}
