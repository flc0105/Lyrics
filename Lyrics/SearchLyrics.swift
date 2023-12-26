//
//  SearchLyrics.swift
//  Lyrics
//
//  Created by Fang Liangchen on 2023/12/26.
//

import SwiftUI
import Foundation

/// Model representing a search result item.
struct SearchResultItem: Identifiable {
    var id: String
    var title: String
    var artist: String
    var album: String
    var duration: String
}

/// Model representing the result of a search.
struct SearchResult: Decodable {
    var result: Result
}

/// Model representing the result of a search.
struct Result: Decodable {
    var songs: [Song]
}

/// Model representing a song.
struct Song: Decodable {
    var id: Int
    var name: String
    var artists: [Artist]
    var album: Album
    var duration: Int
}

/// Model representing an artist.
struct Artist: Decodable {
    var name: String
}

/// Model representing an album.
struct Album: Decodable {
    var name: String
}

/// Function to search for a song based on a keyword.
func searchSong(keyword: String, completion: @escaping (Result?, Error?) -> Void) {
    // Ensure the keyword is properly encoded for a URL.
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        print("Error: Unable to encode keyword")
        return
    }
    
    // Construct the API URL for the search.
    let apiUrl = "https://music.163.com/api/search/get?s=\(encodedKeyword)&type=1&limit=30"
    
    // Create a URL object from the API URL string.
    guard let url = URL(string: apiUrl) else {
        print("Invalid URL")
        return
    }
    
    // Perform a data task to fetch the search results.
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        // Handle any error that occurred during the task.
        if let error = error {
            completion(nil, error)
            return
        }
        
        // Ensure that data was received.
        guard let data = data else {
            print("No data received")
            return
        }
        
        // Attempt to decode the received JSON data.
        do {
            let decoder = JSONDecoder()
            let searchResult = try decoder.decode(SearchResult.self, from: data)
            completion(searchResult.result, nil)
        } catch {
            print("Error decoding JSON: \(error)")
            completion(nil, error)
        }
    }
    // Start the data task.
    task.resume()
}

/// SwiftUI view representing a sub-window.
struct SubWindowView: View {
    
    var onClose: (() -> Void)
    @State var searchText: String = ""
    @State var searchResults: [SearchResultItem]  = [] // Results to be displayed.
    @State var selectedItemId: String? // Selected item ID.
    
    var body: some View {
        VStack {
            HStack {
                // Text field for entering search keyword.
                TextField("Enter search keyword", text: $searchText)
                // Button to initiate the search.
                Button("Search") {
                    // Call the searchButtonTapped method to handle search logic.
                    searchButtonTapped()
                }
            }
            // Table displaying search results.
            Table(searchResults, selection: $selectedItemId) {
                TableColumn("Title", value: \.title)
                TableColumn("Artist", value: \.artist)
                TableColumn("Album", value: \.album)
                TableColumn("Duration", value: \.duration)
            }
            // Context menu for the search results.
            .contextMenu(forSelectionType: SearchResultItem.ID.self
            ) { items in
            } primaryAction: { items in
                // Action when a row is double-clicked.
                if let selectedItem = searchResults.first(where: { $0.id == selectedItemId }) {
                    let id = selectedItem.id
                    debugPrint("Preparing to get lyrics for song ID " + id)
                    
                    // Extract the relevant information from the selected item.
                    let title = selectedItem.title
                    let artist = selectedItem.artist
                    let album = selectedItem.album
                    
                    // Download lyrics and display an alert.
                    download(id: id, artist: artist, title: title, album: album) { combinedLyrics in
                        if let combinedLyrics = combinedLyrics {
                            // Ensure that UI-related code is executed on the main thread
                            DispatchQueue.main.async {
                                showTextAreaAlert(title: "Save Lyrics", message: "Are you sure you want to save the lyrics?", defaultValue: combinedLyrics, firstButtonText: "Download") { text in
                                    saveLyricsToFile(lyrics: text, filePath: getStoredLyricsFolderPath() + (currentTrack ?? "\(artist) - \(title)") + ".lrc")
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                showAlert(title: "Save Lyrics", message: "Failed to fetch lyrics.")
                            }
                        }
                    }
                }
            }
            // Add a border to the table.
            .border(Color.gray, width: 1)
        }
        // Add padding to the entire view.
        .padding()
        // Set the initial value of searchText to currentTrack when the view appears.
        .onAppear() {
            // Check if currentTrack is not empty before setting the searchText and triggering the search logic.
            if let currentTrack = currentTrack, !currentTrack.isEmpty {
                searchText = currentTrack
                // Simulate a button tap to trigger the search logic.
                searchButtonTapped()
            }
        }
        // Perform actions when the view disappears.
        .onDisappear {
            onClose()
            debugPrint("Sub window closed")
        }
    }
    
    
    // Method to handle the search button tap.
    private func searchButtonTapped() {
        // Call the searchSong function with the entered keyword.
        searchSong(keyword: searchText) { result, error in
            // Handle any error returned by the search.
            if let error = error {
                print("Error: \(error)")
                return
            }
            // If there are songs in the result, update the searchResults state.
            if let songs = result?.songs {
                DispatchQueue.main.async {
                    self.searchResults = songs.map {
                        SearchResultItem(id: "\($0.id)", title: $0.name, artist: $0.artists.first?.name ?? "Unknown Artist", album: $0.album.name, duration: $0.duration.millisecondsToFormattedString())
                    }
                }
            }
        }
    }
}

extension Int {
    func millisecondsToFormattedString() -> String {
        let totalSeconds = self / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}



/// Function to save lyrics to a file.
func saveLyricsToFile(lyrics: String, filePath: String) {
    do {
        try lyrics.write(toFile: filePath, atomically: true, encoding: .utf8)
        print("Lyrics saved to: \(filePath)")
    } catch {
        print("Error saving lyrics to file: \(error)")
    }
}



/// Show an alert with a multiline text field
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
