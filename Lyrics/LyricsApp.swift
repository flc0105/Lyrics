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
                    let lyricText = line.replacingOccurrences(of: "\\[.*\\]", with: "", options: .regularExpression, range: nil)
                    
                    // Create a LyricInfo instance and add it to the array
                    let lyricInfo = LyricInfo(id: lyrics.count, text: lyricText, isCurrent: false, playbackTime: timestamp)
                    lyrics.append(lyricInfo)
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
}

/// View model for managing lyrics data.
class LyricsViewModel: ObservableObject {
    /// Published property holding the array of LyricInfo representing the lyrics.
    @Published var lyrics: [LyricInfo] = []
    
    /// Updates the lyrics with a new set of lyrics.
    /// - Parameter newLyrics: The new array of LyricInfo representing the updated lyrics.
    func updateLyrics(newLyrics: [LyricInfo]) {
        lyrics = newLyrics
    }
}

/// The main view model instance for managing lyrics.
var viewModel = LyricsViewModel()

/// The start time for tracking the playback time.
var startTime: TimeInterval = 0

/// A boolean indicating whether the lyrics display is stopped.
var isStopped: Bool = false

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
            LyricInfo(id: 0, text: "Not playing", isCurrent: false, playbackTime: 0),
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

/// SwiftUI view representing the lyrics interface.
struct LyricsView: View {
    
    @State private var currentIndex: Int = 0
    
    var body: some View {
        
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 10) {
                        ForEach(viewModel.lyrics) { lyric in
                            Text(lyric.text)
                                .font(lyric.isCurrent ? .system(size: 14) : .system(size: 14))
                                .foregroundColor(lyric.isCurrent ? .blue : .white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .id(lyric.id)
                        }
                    }
                    .onChange(of: currentIndex) { newValue in
                        // Scroll to the current lyric's position
                        withAnimation() {
                            proxy.scrollTo(currentIndex, anchor: .center)
                        }
                    }
                }
            }
            .onAppear {
                startTimer()
            }
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
        guard !isStopped else {
            return
        }
        
        let currentPlaybackTime = Date().timeIntervalSinceReferenceDate - startTime
        
        for (index, lyric) in viewModel.lyrics.enumerated() {
            if currentPlaybackTime >= lyric.playbackTime {
                currentIndex = index
            }
        }
        
        viewModel.lyrics.indices.forEach { index in
            viewModel.lyrics[index].isCurrent = (index == currentIndex)
        }
        
        // Check if there is a next lyric
        let nextIndex = (currentIndex + 1) % viewModel.lyrics.count
        if nextIndex != currentIndex {
            let currentLyric = viewModel.lyrics[currentIndex]
            let nextLyric = viewModel.lyrics[nextIndex]
            
            // Calculate the delay time
            let delay = nextLyric.playbackTime - currentLyric.playbackTime
            
            // Use asynchronous delay to continue displaying lyrics
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Update the next lyric
                updateLyrics()
            }
        }
    }
    
}


/// Starts displaying lyrics for the currently playing track.
func startLyrics() {
    // Record the start time of lyric display
    let lyricStartTime = Date().timeIntervalSinceReferenceDate
    
    // Reset the stopped flag
    isStopped = false
    
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
            print("Lyrics file loaded: \(lrcPath)")
            
            // Create an LRC parser
            let parser = LRCParser(lrcContent: lrcContent)
            
            // Get the parsed lyrics array
            let lyrics = parser.getLyrics()
            
            // Set the start time for lyrics display
            startTime = Date().timeIntervalSinceReferenceDate - playbackTime
            
            // Update the lyrics in the view model
            viewModel.updateLyrics(newLyrics: lyrics)
            
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
                    startTime = Date.timeIntervalSinceReferenceDate - updatedPlaybackTime
                    print("Playback time updated: \(updatedPlaybackTime)")
                }
            }
        } else {
            print("Failed to read LRC file.")
            return
        }
    }
}

/// Stops displaying lyrics for the currently playing track.
func stopLyrics() {
    // Set the stopped flag
    isStopped = true
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
    }
}



