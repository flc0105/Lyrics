//
//  MediaRemoteController.swift
//  Lyrics
//
//  Created by Fang Liangchen on 2023/12/19.
//

import Foundation
import Cocoa
import Dynamic


var currentTrack: String?


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

enum MRCommand: Int {
    case kMRPlay = 0
    case kMRPause = 1
    case kMRTogglePlayPause = 2
    case kMRStop = 3
    case kMRNextTrack = 4
    case kMRPreviousTrack = 5
}


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


// Get function pointer for MRMediaRemoteSendCommand
let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString)
typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int, AnyObject?) -> Bool
let MRMediaRemoteSendCommand = unsafeBitCast(MRMediaRemoteSendCommandPointer, to: MRMediaRemoteSendCommandFunction.self)


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
            // Call the completion handler with an empty dictionary
            completion(nowPlayingInfo)
            return
        }
        
        // Extract information from the result
        nowPlayingInfo["Artist"] = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
        nowPlayingInfo["Title"] = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
        nowPlayingInfo["ElapsedTime"] = information["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? TimeInterval ?? 0.0
        
        if (UIPreferences.shared.isCoverImageVisible) {
            let artworkData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
            let artwork = artworkData.flatMap { NSImage(data: $0) }
            if (artwork == nil) {
                debugPrint("Artwork is nil.")
            } else if (artwork?.tiffRepresentation == UIPreferences.shared.coverImage?.tiffRepresentation) {
                debugPrint("Artwork has not changed, skipped.")
            } else {
                debugPrint("Artwork change detected, updated.")
                UIPreferences.shared.coverImage = artwork
            }
        }
        
        // Call the completion handler with the updated dictionary
        completion(nowPlayingInfo)
    }
}


/// Updates the album cover based on the currently playing media information.
func updateAlbumCover() {
    
    // Call the Media Remote framework to get now playing information
    MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { information in
        
        // Check if the information is empty
        if information.isEmpty {
            debugPrint("Now playing information is empty.")
            return
        }
        
        // Check if the cover image visibility is enabled
        if (UIPreferences.shared.isCoverImageVisible) {
            
            // Extract the artwork data from the now playing information
            let artworkData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
            
            // Create an NSImage from the artwork data
            let artwork = artworkData.flatMap { NSImage(data: $0) }
            
            // Set the background image in the shared ImageObject
            UIPreferences.shared.coverImage = artwork
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


/// Handles the notification when the now playing information changes.
///
/// - Parameter notification: The notification object.
func handleNowPlayingInfoDidChangeNotification(notification: Notification) {
    getNowPlayingInfo { nowPlayingInfo in
        
        // Check if the now playing information is empty
        guard !nowPlayingInfo.isEmpty else {
            debugPrint("Now playing information is empty.")
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
            debugPrint("Track change detected: \(String(describing: currentTrack)) -> \(track)")
            currentTrack = track
            
            // Check playback state
            getPlaybackState { isPlaying in
                if isPlaying {
                    startLyrics()
                }
            }
        }
    }
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
        debugPrint("Playback state change detected: \(playbackState)")
        
        // Check the playback state and perform actions accordingly
        if playbackState == .playing {
            startLyrics()
        } else {
            stopLyrics()
        }
    }
}


/// Register for notifications related to system playback state and application lifecycle.
func registerNotifications() {
    
    // Bundle Identifier of the application to be monitored
    let targetAppBundleIdentifier = getPlayerNameConfig()
    
    if targetAppBundleIdentifier.isEmpty {
        debugPrint("No app bundle identifier set.")
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
                debugPrint("MediaRemote now playing notifications registered.")
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
                debugPrint("MediaRemote now playing notifications unregistered.")
            }
        }
    }
    
    // Check if the application is already running at startup
    if let targetApp = NSRunningApplication.runningApplications(withBundleIdentifier: targetAppBundleIdentifier).first {
        debugPrint("Application is running: \(targetApp.localizedName ?? "").")
        
        // Register Now Playing notifications
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        debugPrint("MediaRemote now playing notifications registered.")
        
        // Check the current playback state at startup
        getPlaybackState { isPlaying in
            if isPlaying {
                // Handle the case when the application is already playing
            }
        }
    } else {
        debugPrint("Application is not running.")
    }
}


func togglePlayPause() {
    
    MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { information in
        
        let bundleInfo = Dynamic._MRNowPlayingClientProtobuf.initWithData(information["kMRMediaRemoteNowPlayingInfoClientPropertiesData"])
        
        if information.isEmpty {
            debugPrint("Now playing information is empty.")
            return
        }
        
        let playerName = bundleInfo.displayName.asString ?? ""
        let playerBundleIdentifier = bundleInfo.bundleIdentifier.asString ?? ""
        debugPrint("playerName=\(playerName)")
        if playerBundleIdentifier != getPlayerNameConfig() {
            debugPrint("Player not detected running: \(playerName)")
            return
        }
        
        let result = MRMediaRemoteSendCommand(MRCommand.kMRTogglePlayPause.rawValue, nil)
        debugPrint("MRMediaRemoteSendCommand=\(result)")
    })
    
}
