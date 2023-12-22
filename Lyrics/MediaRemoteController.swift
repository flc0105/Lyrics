//
//  MediaRemoteController.swift
//  Lyrics
//
//  Created by Fang Liangchen on 2023/12/19.
//

import Foundation
import Cocoa

// Create a bundle for the MediaRemote framework
let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

// Get function pointer for MRMediaRemoteGetNowPlayingInfo
let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)
typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

// Get function pointer for MRMediaRemoteGetNowPlayingApplicationIsPlaying
let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString)
typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
let MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)

// Get function pointer for MRMediaRemoteRegisterForNowPlayingNotifications
let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString)
typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)

// Get function pointer for MRMediaRemoteUnregisterForNowPlayingNotifications
let MRMediaRemoteUnregisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteUnregisterForNowPlayingNotifications" as CFString)
typealias MRMediaRemoteUnregisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
let MRMediaRemoteUnregisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteUnregisterForNowPlayingNotificationsPointer, to: MRMediaRemoteUnregisterForNowPlayingNotificationsFunction.self)


/// Retrieves information about the currently playing media.
///
/// - Parameters:
///   - completion: A closure to be called once the now playing information is obtained.
///                  The closure takes a dictionary containing information such as artist,
///                  title, and elapsed time as parameters.
func getNowPlayingInfo(completion: @escaping ([String: Any]) -> Void) {
    var nowPlayingInfo: [String: Any] = [:]
    
    // Call the Media Remote framework to get now playing information
    MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { information in
        
        // Check if the information is empty
        if information.isEmpty {
            print("Could not find the specified now playing client")
            // Call the completion handler with an empty dictionary
            completion(nowPlayingInfo)
            return
        }
        
        // Extract information from the result
        nowPlayingInfo["Artist"] = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
        nowPlayingInfo["Title"] = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
        nowPlayingInfo["ElapsedTime"] = information["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? TimeInterval ?? 0.0
        
        if (ImageObject.shared.isCoverImageVisible) {
            let artworkData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
            let artwork = artworkData.flatMap { NSImage(data: $0) }
            ImageObject.shared.backgroundImage = artwork
        }
        
        // Call the completion handler with the updated dictionary
        completion(nowPlayingInfo)
    }
}



func updateAlbumCover() {

    // Call the Media Remote framework to get now playing information
    MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { information in
        
        // Check if the information is empty
        if information.isEmpty {
            print("Could not find the specified now playing client")
            return
        }
        
        if (ImageObject.shared.isCoverImageVisible) {
            let artworkData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
            let artwork = artworkData.flatMap { NSImage(data: $0) }
            ImageObject.shared.backgroundImage = artwork
        }
    
    }
}




/// Retrieves the playback state of the currently playing media application.
///
/// - Parameter completion: A closure to be called once the playback state is obtained.
///                         The closure takes a boolean parameter indicating whether
///                         the media application is currently playing or not.
func getPlaybackState(completion: @escaping (Bool) -> Void) {
    // Call the Media Remote framework to get the playback state
    MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { isPlaying in
        // Call the completion handler with the obtained playback state
        completion(isPlaying)
    }
}


var currentTrack: String?

/// Handles the notification when the now playing information changes.
///
/// - Parameter notification: The notification object.
func handleNowPlayingInfoDidChangeNotification(notification: Notification) {
    getNowPlayingInfo { nowPlayingInfo in
        
        // Check if the now playing information is empty
        guard !nowPlayingInfo.isEmpty else {
            print("Now playing information is empty.")
            return
        }
        
        // Extract artist and title
        let artist = nowPlayingInfo["Artist"] as? String ?? ""
        let title = nowPlayingInfo["Title"] as? String ?? ""
        let track = "\(artist) - \(title)"
        
        // Check if the current track is nil or if it's the same as the new track
        
        if currentTrack == nil {
            currentTrack = track
            return
        }
        
        if track == currentTrack {
            return
        } else {
            print("Track change detected: \(String(describing: currentTrack)) -> \(track)")
            currentTrack = track
            
            // Check playback state
            getPlaybackState { isPlaying in
                if isPlaying {
                    // Take action when the playback state is playing
                    startLyrics()
                }
            }
        }
    }
}

/// Constructs and returns the path for the LRC (Lyrics) file based on the artist and title of the song.
///
/// - Parameters:
///   - artist: The artist of the song.
///   - title: The title of the song.
/// - Returns: The file path for the LRC file.
func getLRCPath(artist: String, title: String) -> String {
    // Create the file name by combining artist and title
    let fileName = "\(artist) - \(title).lrc"
    
    // Replace illegal characters in the file name with underscores
    let illegalCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
    let replacedFileName = fileName.components(separatedBy: illegalCharacters).joined(separator: "_")
    
    // Construct and return the full file path
    return "\(getStoredLyricsFolderPath())\(replacedFileName)"
}

/// Enum representing different playback states for a media application.
enum PlaybackState: Int {
    /// The media application is terminated.
    case terminated = 0
    /// The media application is currently playing.
    case playing = 1
    /// The media application is paused.
    case paused = 2
    /// The media application is stopped.
    case stopped = 3
}

/// Handles the change in playback state of the currently playing media application.
///
/// - Parameter notification: The notification object containing information about the playback state change.
func handleNowPlayingApplicationPlaybackStateDidChange(notification: Notification) {
    // Extract the raw playback state from the notification's user info
    let rawPlaybackState = notification.userInfo?["kMRMediaRemotePlaybackStateUserInfoKey"] as? Int ?? 3
    
    // Convert the raw playback state to a PlaybackState enum
    if let playbackState = PlaybackState(rawValue: rawPlaybackState) {
        // Print the detected playback state
        print("Playback state change detected: \(playbackState)")
        
        // Check the playback state and perform actions accordingly
        if playbackState == .playing {
            startLyrics()
        } else {
            stopLyrics()
        }
    }
}


/// Retrieves the stored player name from UserDefaults.
///
/// If the player name is not found in UserDefaults, it registers a default value ("com.roon.Roon").
///
/// - Returns: The stored player name, or the default value if not found.
func getStoredPlayerName() -> String {
    UserDefaults.standard.register(defaults: ["PlayerPackageName": "com.roon.Roon"])
    return UserDefaults.standard.string(forKey: "PlayerPackageName") ?? ""
}

/// Retrieves the stored lyrics folder path from UserDefaults.
///
/// If the folder path is not found in UserDefaults, it registers a default value ("/Users/flc/Desktop/Lyrics/").
///
/// - Returns: The stored lyrics folder path, or the default value if not found.
func getStoredLyricsFolderPath() -> String {
    UserDefaults.standard.register(defaults: ["LyricsFolder": "/Users/flc/Desktop/Lyrics/"])
    return UserDefaults.standard.string(forKey: "LyricsFolder") ?? ""
}


/// Register notifications for Now Playing info and application playback state changes.
func registerNotifications() {
    //    let targetAppBundleIdentifier = "com.roon.Roon"
    
    // Bundle Identifier of the application to be monitored
    let targetAppBundleIdentifier = getStoredPlayerName()
    
    if targetAppBundleIdentifier.isEmpty {
        print("Player package name not set.")
        return
    }
    
    let notificationCenter = NotificationCenter.default
    
    // Register for Now Playing info change notification
    notificationCenter.addObserver(forName: Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
                                   object: nil,
                                   queue: nil,
                                   using: handleNowPlayingInfoDidChangeNotification)
    
    // Register for application playback state change notification
    notificationCenter.addObserver(forName: Notification.Name("kMRMediaRemoteNowPlayingApplicationPlaybackStateDidChangeNotification"),
                                   object: nil,
                                   queue: nil,
                                   using: handleNowPlayingApplicationPlaybackStateDidChange)
    
    let center = NSWorkspace.shared.notificationCenter
    
    // Register for the launch of an application notification
    center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification,
                       object: nil,
                       queue: OperationQueue.main) { (notification: Notification) in
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            if app.bundleIdentifier == targetAppBundleIdentifier {
                // Register Now Playing notifications
                MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
                print("MediaRemote now playing notifications registered.")
            }
        }
    }
    
    // Register for the termination of an application notification
    center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification,
                       object: nil,
                       queue: OperationQueue.main) { (notification: Notification) in
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            if app.bundleIdentifier == targetAppBundleIdentifier {
                // Unregister Now Playing notifications
                MRMediaRemoteUnregisterForNowPlayingNotifications(DispatchQueue.main)
                print("MediaRemote now playing notifications unregistered.")
            }
        }
    }
    
    // Check if the application is already running at startup
    if let targetApp = NSRunningApplication.runningApplications(withBundleIdentifier: targetAppBundleIdentifier).first {
        print("Application is running: \(targetApp.localizedName ?? "").")
        
        // Register Now Playing notifications
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        print("MediaRemote now playing notifications registered.")
        
        // Check the current playback state at startup
        getPlaybackState { isPlaying in
            if isPlaying {
                // Handle the case when the application is already playing
            }
        }
    } else {
        print("Application is not running.")
    }
}
