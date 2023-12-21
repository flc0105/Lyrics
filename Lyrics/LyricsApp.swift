//
//  LyricsApp.swift
//  Lyrics
//
//  Created by Fang Liangchen on 2023/12/19.
//

import SwiftUI


import Foundation

/// Lyrics parser for handling LRC (Lyric) files.
class LRCParser {
    var lyrics: [LyricInfo] = []
    
    /// Initializes the parser with the content of an LRC file.
    /// - Parameter lrcContent: Content of the LRC file.
    init(lrcContent: String) {
        parseLRCContent(lrcContent)
    }
    
    /// Parses the content of an LRC file.
    /// - Parameter content: Content of the LRC file as a string.
    func parseLRCContent(_ content: String) {
        // Split the content into lines
        let lines = content.components(separatedBy: "\n")
        // Use regular expression to match timestamps
        let regex = try! NSRegularExpression(pattern: "\\[([0-9]+:[0-9]+.[0-9]+)\\]", options: [])
        
        for line in lines {
            // Find matches for timestamps in each line
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
            if let match = matches.first {
                // Extract the time string
                let timeString = (line as NSString).substring(with: match.range(at: 1))
                // Split the time string into minutes and seconds
                let timeComponents = timeString.components(separatedBy: ":")
                if let minutes = Double(timeComponents[0]), let seconds = Double(timeComponents[1]) {
                    // Calculate the timestamp
                    let timestamp = minutes * 60 + seconds
                    // Extract the lyric text
                    //                    let lyricText = line.replacingOccurrences(of: "\\[.*\\]", with: "", options: .regularExpression, range: nil)
                    let lyricText = line.replacingOccurrences(of: "\\[([0-9]+:[0-9]+.[0-9]+)\\]", with: "", options: .regularExpression, range: nil)
                    
                    // Create a LyricInfo instance and add it to the array
                    
                    // Check if lyrics array is not empty and timestamps are the same
                    if let lastTimestamp = lyrics.last?.playbackTime, timestamp == lastTimestamp {
                        lyrics.append(LyricInfo(id: lyrics.count, text: lyricText, isCurrent: false, playbackTime: timestamp, isTranslation: true))
                    } else {
                        lyrics.append(LyricInfo(id: lyrics.count, text: lyricText, isCurrent: false, playbackTime: timestamp, isTranslation: false))
                    }
                }
            }
        }
        
        // Sort the lyrics array based on timestamps
        lyrics.sort { $0.playbackTime < $1.playbackTime }
    }
    
    /// Gets the parsed lyrics as an array of LyricInfo.
    /// - Returns: An array of LyricInfo instances representing the lyrics.
    func getLyrics() -> [LyricInfo] {
        return lyrics
    }
}


/// LyricInfo structure representing information for a single line of lyrics.
struct LyricInfo: Identifiable {
    /// Unique identifier for the lyric line.
    let id: Int
    /// The text of the lyric line.
    let text: String
    /// A boolean indicating whether the lyric line is currently being played.
    var isCurrent: Bool
    /// The playback time associated with the lyric line.
    var playbackTime: TimeInterval
    /// A boolean indicating whether the lyric is a translation.
    var isTranslation: Bool
}

/// View model for managing lyrics data.
class LyricsViewModel: ObservableObject {
    /// Published property holding the array of LyricInfo representing the lyrics.
    @Published var lyrics: [LyricInfo] = []
    
    /// Shared instance of LyricsViewModel.
    static let shared = LyricsViewModel()
    
    /// Published property holding the current index of the lyrics.
    @Published var currentIndex: Int = 0
    
    /// Updates the lyrics with a new set of lyrics.
    /// - Parameter newLyrics: The new array of LyricInfo representing the updated lyrics.
    func updateLyrics(newLyrics: [LyricInfo]) {
        lyrics = newLyrics
    }
}

/// The main view model instance for managing lyrics.
//var viewModel = LyricsViewModel()
var viewModel = LyricsViewModel.shared

/// The start time for tracking the playback time.
var startTime: TimeInterval = 0

/// A boolean indicating whether the lyrics display is stopped.
var isStopped: Bool = true

/// AppDelegate class responsible for managing the application's lifecycle.
class AppDelegate: NSObject, NSApplicationDelegate {
    /// The main window of the application.
    var window: NSWindow!
    
    /// Called when the application finishes launching.
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Set the start time
        startTime = Date.timeIntervalSinceReferenceDate
        
        // Initialize the lyrics with a default "Not playing" line
        viewModel.lyrics =  [
            LyricInfo(id: 0, text: "Not playing", isCurrent: false, playbackTime: 0, isTranslation: false),
        ]
        
        // Initialize the application
        registerNotifications()
        
        // Create and configure the main window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false)
        
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
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isHidden = true
        window.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)!.isHidden = true
        window.center()
        window.setFrameAutosaveName("LyricsWindow")
        window.makeKeyAndOrderFront(nil)
        window.styleMask.remove(.resizable)
    }
    
    /// Called when the main window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Terminate the application when the last window is closed
        return true
    }
    
}


/// Copies the given text to the clipboard.
/// - Parameter text: The text to be copied.
private func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    print("Lyrics copied to clipboard: \(text)")
}

/// SwiftUI view representing the lyrics interface.
struct LyricsView: View {
    
    @ObservedObject var lyricViewModel: LyricsViewModel = LyricsViewModel.shared
    @State private var isCopiedAlertPresented: Bool = false
    
    
    var body: some View {
        
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 10) {
                        ForEach(viewModel.lyrics) { lyric in
                            Text(lyric.text)
                                .font(lyric.isCurrent ? .system(size: 14) : .system(size: 14))
                                .foregroundColor(lyric.isCurrent ? .blue : .white)
                            //                                .opacity(lyric.isCurrent ? 1.0 : 0.5)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, lyric.isTranslation ? -40 : 20)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .id(lyric.id)
                                .onTapGesture {
                                    copyToClipboard(lyric.text)
                                    isCopiedAlertPresented = true
                                }
                        }
                    }
                    .onChange(of: lyricViewModel.currentIndex) { [oldValue = lyricViewModel.currentIndex] newValue in
                        
                        debugPrint("oldValue=\(oldValue), newValue=\(newValue)")
                        
                        // Scroll to the current lyric's position
                        withAnimation() {
                            
                            viewModel.lyrics.indices.forEach { index in
                                viewModel.lyrics[index].isCurrent = false
                            }
                            
                            if (oldValue > 0 && oldValue < viewModel.lyrics.count) {
                                viewModel.lyrics[oldValue].isCurrent = true
                                proxy.scrollTo(oldValue, anchor: .center)
                            }
                            
                        }
                    }
                }
            }
        }
        .onAppear {
            startTimer()
        }.alert(isPresented: $isCopiedAlertPresented) {
            Alert(
                title: Text("Lyrics Copied"),
                message: Text("Lyrics text has been copied to the clipboard."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    
    /// Start a timer to update lyrics every second.
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isStopped {
                updateLyrics()
            }
        }
    }
    
    
    /// Update the lyrics based on the current playback time.
    private func updateLyrics() {
        // Check if lyrics display is stopped
        guard !isStopped else {
            return
        }
        
        // Check if the current lyric index is within the array bounds
        guard lyricViewModel.currentIndex >= 0 && lyricViewModel.currentIndex < viewModel.lyrics.count else {
            print("Playback is over.")
            stopLyrics()
            return
        }
        
        // Calculate the current playback progress
        let currentPlaybackTime = Date().timeIntervalSinceReferenceDate - startTime
        
        // Get the current lyric
        let currentLyric = viewModel.lyrics[lyricViewModel.currentIndex]
        
        // Check if it's time to display the current lyric
        if currentPlaybackTime >= currentLyric.playbackTime {
            debugPrint("currentPlayBackTime=\(currentPlaybackTime), currentLyricPlaybackTime=\(currentLyric.playbackTime), currentIndex=\(lyricViewModel.currentIndex), currentLyricText=\(currentLyric.text)")
            
            // Increase the lyric index
            lyricViewModel.currentIndex += 1
            
            // Check if there is a next lyric
            if lyricViewModel.currentIndex < viewModel.lyrics.count {
                let nextLyric = viewModel.lyrics[lyricViewModel.currentIndex]
                
                // Skip translation lyrics
                if nextLyric.isTranslation {
                    updateLyrics()
                    return
                }
                
                // Calculate the delay time
                let delay = nextLyric.playbackTime - currentLyric.playbackTime
                
                // Use asynchronous delay to continue displaying lyrics
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    // Update the next lyric
                    updateLyrics()
                }
            }
        }
    }}

// Find the lyric index corresponding to the specified start time
private func findStartingLyricIndex(_ startTime: TimeInterval) -> Int {
    for (index, lyric) in viewModel.lyrics.enumerated() {
        if lyric.playbackTime >= startTime {
            return index
        }
    }
    return -1
}

/// Update the playback time based on the specified playback time.
func updatePlaybackTime(playbackTime: TimeInterval) {
    // Set the start time based on the playback time
    startTime = Date.timeIntervalSinceReferenceDate - playbackTime
    // Reset the lyric index to the beginning
    LyricsViewModel.shared.currentIndex = 0
    // Find and set the starting lyric index
    LyricsViewModel.shared.currentIndex = findStartingLyricIndex(playbackTime)
}


/// Starts displaying lyrics for the currently playing track.
func startLyrics() {
    // Record the start time of lyric display
    let lyricStartTime = Date().timeIntervalSinceReferenceDate
    
    // Retrieve now playing information
    getNowPlayingInfo { nowPlayingInfo in
        // Check if the now playing information is empty
        guard !nowPlayingInfo.isEmpty else {
            print("Now playing information is empty.")
            return
        }
        
        // Get playback time
        guard let playbackTime = nowPlayingInfo["ElapsedTime"] as? TimeInterval else {
            print("Failed to get playback time.")
            return
        }
        
        // Extract artist and title
        let artist = nowPlayingInfo["Artist"] as? String ?? ""
        let title = nowPlayingInfo["Title"] as? String ?? ""
        
        // Get the path of the lyrics file
        let lrcPath = getLRCPath(artist: artist, title: title)
        
        // Try to read the contents of the lyrics file
        if let lrcContent = try? String(contentsOfFile: lrcPath) {
            debugPrint("Lyrics file loaded: \(lrcPath)")
            
            // Reset the stopped flag
            isStopped = false
            
            // Create an LRC parser
            let parser = LRCParser(lrcContent: lrcContent)
            
            // Get the parsed lyrics array
            let lyrics = parser.getLyrics()
            
            // Update the lyrics in the view model
            viewModel.updateLyrics(newLyrics: lyrics)
            
            updatePlaybackTime(playbackTime: playbackTime)
            
            // 3 seconds later, update and calibrate the playback time
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                getNowPlayingInfo { nowPlayingInfo in
                    guard var updatedPlaybackTime = nowPlayingInfo["ElapsedTime"] as? TimeInterval else {
                        print("Failed to update playback time.")
                        return
                    }
                    
                    // Calculate the time gap
                    let gap = Date().timeIntervalSinceReferenceDate - lyricStartTime
                    updatedPlaybackTime = updatedPlaybackTime + gap
                    updatePlaybackTime(playbackTime: updatedPlaybackTime)
                    debugPrint("Playback time updated: \(updatedPlaybackTime)")
                }
            }
        } else {
            print("Failed to read LRC file.")
            
            // Set the start time and display a default lyric
            startTime = Date().timeIntervalSinceReferenceDate
            viewModel.lyrics =  [
                LyricInfo(id: 0, text: "\(artist) - \(title)", isCurrent: true, playbackTime: 0, isTranslation: false),
                LyricInfo(id: 1, text: "Lyric not found", isCurrent: false, playbackTime: 1, isTranslation: false),
            ]
            
            return
        }
    }
}


/// Stops displaying lyrics for the currently playing track.
func stopLyrics() {
    isStopped = true
}





func showAlert(title: String, message: String, firstButtonTitle: String = "OK", onFirstButtonTap: (() -> Void)? = nil, showCancelButton: Bool = false) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: firstButtonTitle)
    
    if showCancelButton {
        alert.addButton(withTitle: "Cancel")
    }
    
    let response = alert.runModal()
    
    if response == .alertFirstButtonReturn, let onFirstButtonTap = onFirstButtonTap {
        onFirstButtonTap()
    }
}



func showInputAlert(title: String, message: String, defaultValue: String, onFirstButtonTap: @escaping (String) -> Void) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    
    // 添加输入框
    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField.stringValue = defaultValue
    alert.accessoryView = textField
    
    // 添加按钮
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Cancel")
    
    // 处理按钮点击
    if alert.runModal() == .alertFirstButtonReturn {
        let inputText = textField.stringValue
        guard !inputText.isEmpty else {
            showAlert(title: "Settings Not Saved", message: "Your input is empty.")
            return
        }
        guard inputText != defaultValue else {
            return  // 与默认值相同，不执行后续操作
        }
        onFirstButtonTap(inputText)
    }
}

//func showFolderPicker() {
//    let folderPicker = NSOpenPanel()
//    folderPicker.title = "Select a Folder"
//    folderPicker.showsResizeIndicator = true
//    folderPicker.showsHiddenFiles = false
//    folderPicker.canChooseDirectories = true
//    folderPicker.canChooseFiles = false
//    folderPicker.canCreateDirectories = false
//    folderPicker.allowsMultipleSelection = false
//
//    let response = folderPicker.runModal()
//
//    if response == NSApplication.ModalResponse.OK {
//        // User clicked "OK", get the selected folder URL
//        if let folderURL = folderPicker.urls.first {
//            let selectedFolderPath = folderURL.path
//            print("Selected Folder Path: \(selectedFolderPath)")
//            // Do something with the selectedFolderPath
//        }
//    }
//}



import Cocoa

func showFolderPicker(message: String, completion: @escaping (String?) -> Void) {
    let folderPicker = NSOpenPanel()
    folderPicker.message = message
    folderPicker.showsResizeIndicator = true
    folderPicker.showsHiddenFiles = false
    folderPicker.canChooseDirectories = true
    folderPicker.canChooseFiles = false
    folderPicker.canCreateDirectories = false
    folderPicker.allowsMultipleSelection = false
    
    let response = folderPicker.runModal()
    
    if response == NSApplication.ModalResponse.OK {
        // User clicked "OK", get the selected folder URL
        if let folderURL = folderPicker.urls.first {
            let selectedFolderPath = folderURL.path
            // Execute the completion closure with the selected folder path
            completion(selectedFolderPath)
        } else {
            // No folder selected
            completion(nil)
        }
    } else {
        // User clicked "Cancel"
        completion(nil)
    }
}



/// The main entry point for the LyricsApp.
@main
struct LyricsApp: App {
    
    /// The app delegate for managing the application's lifecycle.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// The body of the app scene.
    var body: some Scene {
        // Settings scene
        Settings {
            EmptyView()
        }
        .commands {
            CommandMenu("Calibration") {
                Button("1 Second Faster") {
                    startTime = startTime - 1
                }
                .keyboardShortcut("+");
                Button("1 Second Slower") {
                    startTime = startTime + 1
                }
                .keyboardShortcut("-")
            };
            CommandMenu("Configuration") {
                Button("Player") {
                    let storedPlayerName = getStoredPlayerName()
                    showInputAlert(title: "Configure Player",
                                   message: "Please enter the app bundle identifier of the player used to register for notifications.",
                                   defaultValue: storedPlayerName,
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
                };
                Button("Lyrics Folder") {
                    showFolderPicker(message: "Please select the lyrics folder, the current lyrics folder path is: \(getStoredLyricsFolderPath())") { selectedFolderPath in
                        if var folderPath = selectedFolderPath {
                            if !folderPath.hasSuffix("/") {
                                folderPath.append("/")
                            }
                            UserDefaults.standard.set(folderPath, forKey: "LyricsFolder")
                            showAlert(title: "Settings Saved", message: "Lyrics folder has been successfully set: \(getStoredLyricsFolderPath())")
                        }
                    }
                    
                    
                }
            }
        }
    }
}

