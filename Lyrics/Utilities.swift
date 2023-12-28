//
//  CommonUtils.swift
//  Lyrics
//
//  Created by Fang Liangchen on 2023/12/28.
//

import Foundation
import SwiftUI


/// Displays an informational alert with customizable title, message, and button options.
///
/// - Parameters:
///   - title: The title of the alert.
///   - message: The informative text of the alert.
///   - firstButtonTitle: The title of the first button (default is "OK").
///   - onFirstButtonTap: A closure to be executed when the first button is tapped.
///   - showCancelButton: A flag indicating whether to show the cancel button (default is false).
func showAlert(title: String, message: String, firstButtonTitle: String = "OK", onFirstButtonTap: (() -> Void)? = nil, showCancelButton: Bool = false) {
    // Create an NSAlert instance
    let alert = NSAlert()
    // Set the title, informative text, and style of the alert
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    // Add the first button with the specified title
    alert.addButton(withTitle: firstButtonTitle)
    
    // Add a cancel button if specified
    if showCancelButton {
        alert.addButton(withTitle: "Cancel")
    }
    
    // Run the modal and handle the response
    let response = alert.runModal()
    
    // Execute the closure associated with the first button if clicked
    if response == .alertFirstButtonReturn, let onFirstButtonTap = onFirstButtonTap {
        onFirstButtonTap()
    }
}


/// Displays an informational alert with an input field and customizable title and message.
///
/// - Parameters:
///   - title: The title of the alert.
///   - message: The informative text of the alert.
///   - defaultValue: The default value for the input field.
///   - onFirstButtonTap: A closure to be executed when the "Save" button is tapped, providing the entered text.
func showInputAlert(title: String, message: String, defaultValue: String, onFirstButtonTap: @escaping (String) -> Void) {
    // Create an NSAlert instance
    let alert = NSAlert()
    // Set the title, informative text, and style of the alert
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    
    // Add an input field to the alert
    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
    textField.stringValue = defaultValue
    alert.accessoryView = textField
    
    // Add Save and Cancel buttons
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Cancel")
    
    // Handle button click
    if alert.runModal() == .alertFirstButtonReturn {
        // Get the input text and execute the closure
        let inputText = textField.stringValue
        guard !inputText.isEmpty else {
            showAlert(title: "Settings Not Saved", message: "Your input is empty.")
            return
        }
        guard inputText != defaultValue else {
            return  // No action if the input is the same as the default value
        }
        onFirstButtonTap(inputText)
    }
}


/// Displays a folder picker dialog for selecting a folder and executes a completion closure with the selected folder path.
///
/// - Parameters:
///   - message: The message displayed in the folder picker.
///   - defaultFolderPath: The default folder path (optional).
///   - completion: A closure to be executed with the selected folder path.
func showFolderPicker(message: String, defaultFolderPath: String?, completion: @escaping (String?) -> Void) {
    // Create an NSOpenPanel instance for folder picking
    let folderPicker = NSOpenPanel()
    // Set the message and properties of the panel
    folderPicker.message = message
    folderPicker.showsResizeIndicator = true
    folderPicker.showsHiddenFiles = false
    folderPicker.canChooseDirectories = true
    folderPicker.canChooseFiles = false
    folderPicker.canCreateDirectories = false
    
    // Set default folder path if provided
    if let defaultPath = defaultFolderPath {
        folderPicker.directoryURL = URL(fileURLWithPath: defaultPath)
    }
    
    // Run the panel and handle the response
    let response = folderPicker.runModal()
    
    if response == NSApplication.ModalResponse.OK {
        // User clicked "OK", get the selected folder URL
        if let folderURL = folderPicker.urls.first {
            // Get the path from the URL and execute the completion closure
            let selectedFolderPath = folderURL.path
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


/// Displays an informational alert with a multiline text area and customizable title, message, and button options.
///
/// - Parameters:
///   - title: The title of the alert.
///   - message: The informative text of the alert.
///   - defaultValue: The default value for the text area.
///   - firstButtonText: The title of the first button.
///   - onFirstButtonTap: A closure to be executed when the first button is tapped, providing the entered text.
func showTextAreaAlert(title: String, message: String, defaultValue: String, firstButtonText: String, onFirstButtonTap: @escaping (String) -> Void) {
    // Create an NSAlert instance
    let alert = NSAlert()
    // Set the title, informative text, and style of the alert
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    
    // Create an NSTextView and wrap it in an NSScrollView
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
    let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
    textView.string = defaultValue
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    
    // Add the NSScrollView to the alert
    alert.accessoryView = scrollView
    
    // Add buttons
    alert.addButton(withTitle: firstButtonText)
    alert.addButton(withTitle: "Cancel")
    
    // Handle button click
    if alert.runModal() == .alertFirstButtonReturn {
        // Get the input text and execute the closure
        let inputText = textView.string
        guard !inputText.isEmpty else {
            showAlert(title: "Download Failed", message: "The text area is empty.")
            return
        }
        onFirstButtonTap(inputText)
    }
}


/// Converts milliseconds to a formatted time string (mm:ss).
///
/// - Parameter timeInterval: The time interval in milliseconds.
/// - Returns: The formatted time string.
func millisecondsToFormattedString(_ timeInterval: TimeInterval) -> String {
    let totalSeconds = Int(timeInterval / 1000)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d", minutes, seconds)
}


/// Converts seconds to a formatted time string (mm:ss).
///
/// - Parameter timeInterval: The time interval in seconds.
/// - Returns: The formatted time string.
func secondsToFormattedString(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval / 60)
    let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
    return String(format: "%02d:%02d", minutes, seconds)
}


/// Converts a timestamp string to a time interval.
/// - Parameter timestamp: The timestamp string to be converted (mm:ss.SSS).
/// - Returns: The time interval representation of the timestamp.
func lyricsTimestampToTimeInterval(_ timestamp: String) -> TimeInterval? {
    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SSS"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    // Use regular expression to match the valid part of the timestamp string.
    if let match = timestamp.range(of: "\\d+:\\d+\\.\\d+", options: .regularExpression) {
        let validTimestamp = String(timestamp[match])
        
        // Convert the valid timestamp to a time interval.
        if let date = formatter.date(from: validTimestamp) {
            return date.timeIntervalSince1970
        }
    }
    return nil
}


/// Converts a time interval to a timestamp string.
/// - Parameter timeInterval: The time interval to be converted.
/// - Returns: The timestamp string representation of the time interval (mm:ss.SS).
func timeIntervalToLyricsTimestamp(_ timeInterval: TimeInterval) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SS"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    // Convert the time interval to a timestamp string.
    let date = Date(timeIntervalSince1970: timeInterval)
    return formatter.string(from: date)
}


/// Retrieves the stored player name from UserDefaults.
///
/// If the player name is not found in UserDefaults, it registers a default value ("com.roon.Roon").
///
/// - Returns: The stored player name, or the default value if not found.
func getPlayerNameConfig() -> String {
    UserDefaults.standard.register(defaults: ["PlayerPackageName": "com.roon.Roon"])
    return UserDefaults.standard.string(forKey: "PlayerPackageName") ?? ""
}


/// Retrieves the stored lyrics folder path from UserDefaults.
///
/// If the folder path is not found in UserDefaults, it registers a default value ("/Users/flc/Desktop/Lyrics/").
///
/// - Returns: The stored lyrics folder path, or the default value if not found.
func getLyricsFolderPathConfig() -> String {
    UserDefaults.standard.register(defaults: ["LyricsFolder": "/Users/flc/Desktop/Lyrics/"])
    return UserDefaults.standard.string(forKey: "LyricsFolder") ?? ""
}


/// Retrieves the stored state of cover image visibility from UserDefaults.
///
/// If the state is not found in UserDefaults, it registers a default value (false).
///
/// - Returns: The stored state of cover image visibility, or the default value if not found.
func isCoverImageVisibleConfig() -> Bool {
    UserDefaults.standard.register(defaults: ["IsCoverImageVisible": false])
    return UserDefaults.standard.bool(forKey: "IsCoverImageVisible")
}


/// Retrieves the stored state of playback progress visibility from UserDefaults.
///
/// If the state is not found in UserDefaults, it registers a default value (true).
///
/// - Returns: The stored state of playback progress visibility, or the default value if not found.
func isPlaybackProgressVisibleConfig() -> Bool {
    UserDefaults.standard.register(defaults: ["IsPlaybackProgressVisible": true])
    return UserDefaults.standard.bool(forKey: "IsPlaybackProgressVisible")
}


/// Secure a file name by replacing illegal characters with underscores.
/// - Parameter fileName: The original file name to be secured.
/// - Returns: The secured file name with illegal characters replaced by underscores.
func secureFileName(fileName: String) -> String {
    // Replace illegal characters in the file name with underscores
    let illegalCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
    return fileName.components(separatedBy: illegalCharacters).joined(separator: "_")
}


/// Constructs and returns the path for the LRC (Lyrics) file based on the artist and title of the song.
///
/// - Parameters:
///   - artist: The artist of the song.
///   - title: The title of the song.
/// - Returns: The file path for the LRC file.
func getLyricsPath(artist: String, title: String) -> String {
    // Create the file name by combining artist and title
    let fileName = secureFileName(fileName: "\(artist) - \(title).lrc")
    // Construct and return the full file path
    return "\(getLyricsFolderPathConfig())\(fileName)"
}


/// Saves lyrics to a file with a specific file name.
///
/// - Parameters:
///   - lyrics: The lyrics content to be saved.
///   - artist: The artist name for file naming.
///   - title: The title name for file naming.
func saveLyricsToFile(lyrics: String, artist: String, title: String) {
    let filePath = getLyricsFolderPathConfig() + secureFileName(fileName: (currentTrack ?? "\(artist) - \(title)")  + ".lrc")
    do {
        try lyrics.write(toFile: filePath, atomically: true, encoding: .utf8)
        print("Lyrics saved to: \(filePath)")
    } catch {
        print("Error saving lyrics to file: \(error)")
    }
}


/// Copies the given text to the clipboard.
/// - Parameter text: The text to be copied.
func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    print("Lyrics copied to clipboard: \(text)")
}
