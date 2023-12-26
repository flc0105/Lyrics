//
//  DownloadLyrics.swift
//  Lyrics
//
//  Created by Fang Liangchen on 2023/12/26.
//


import Foundation

/// Model representing a single lyric item.
struct LyricItem {
    let timestamp: TimeInterval
    let content: String
}

/// Downloads lyrics for a given song ID.
/// - Parameters:
///   - id: The ID of the song for which lyrics are to be downloaded.
///   - completion: A closure to be called with the downloaded lyrics or `nil` if an error occurs.
func download(id: String, completion: @escaping (String?) -> Void) {
    let urlString = "https://music.163.com/api/song/lyric"
    let parameters = ["tv": "-1", "lv": "-1", "kv": "-1", "id": id]
    
    // Construct the URL for the lyric API with the given parameters.
    var urlComponents = URLComponents(string: urlString)
    urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
    guard let url = urlComponents?.url else {
        print("Invalid URL")
        completion(nil)
        return
    }
    
    // Perform a data task to download lyric data from the API.
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        // Handle any error that occurred during the data task.
        if let error = error {
            print("Error: \(error)")
            completion(nil)
            return
        }
        
        do {
            // Ensure that data was received.
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            // Attempt to parse the received JSON data.
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            // Extract lyric data from the JSON response.
            if let lrc = json?["lrc"] as? [String: Any], let lrcText = lrc["lyric"] as? String,
               let tlyric = json?["tlyric"] as? [String: Any], let tlyricText = tlyric["lyric"] as? String {
                
                // Parse lyric text into LyricItem objects.
                let lrcItems = parseLyric(lrcText)
                let tlyricItems = parseLyric(tlyricText)
                
                // Combine and sort lyric items based on timestamp.
                let combinedItems = (lrcItems + tlyricItems).sorted { $0.timestamp < $1.timestamp }
                
                // Generate a string representation of the combined and sorted lyric items.
//                let combinedLyrics = combinedItems.map { "[\(timeIntervalToTimestamp($0.timestamp))] \($0.content)" }.joined(separator: "\n")
                let combinedLyrics = combinedItems.map { "[\(timeIntervalToTimestamp($0.timestamp))] \($0.content.trimmingCharacters(in: .whitespacesAndNewlines))" }.joined(separator: "\n")

                
                // Return the result through the completion closure.
                completion(combinedLyrics)
            } else {
                print("Failed to parse lyrics from JSON")
                completion(nil)
            }
        } catch {
            print("Error parsing JSON: \(error)")
            completion(nil)
        }
    }
    // Start the data task.
    task.resume()
}

/// Parses the lyric text and returns an array of lyric items.
/// - Parameter lyricText: The raw lyric text to be parsed.
/// - Returns: An array of `LyricItem` objects.
func parseLyric(_ lyricText: String) -> [LyricItem] {
    var lyricItems = [LyricItem]()
    
    // Split the lyric text into lines.
    let lines = lyricText.components(separatedBy: "\n")
    
    // Iterate through each line to extract timestamp and content.
    for line in lines {
        // Use regular expression to extract timestamp and lyric content.
        if let match = line.range(of: "\\[(\\d+:\\d+\\.\\d+)\\]", options: .regularExpression) {
            let timestampString = String(line[match])
            let content = line.replacingOccurrences(of: "\\[(\\d+:\\d+\\.\\d+)\\]", with: "", options: .regularExpression)
            
            // Convert the timestamp to a time interval.
            if let timestamp = timestampToTimeInterval(timestampString) {
                let lyricItem = LyricItem(timestamp: timestamp, content: content)
                lyricItems.append(lyricItem)
            }
        }
    }
    
    return lyricItems
}

/// Converts a timestamp string to a time interval.
/// - Parameter timestamp: The timestamp string to be converted.
/// - Returns: The time interval representation of the timestamp.
func timestampToTimeInterval(_ timestamp: String) -> TimeInterval? {
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
/// - Returns: The timestamp string representation of the time interval.
func timeIntervalToTimestamp(_ timeInterval: TimeInterval) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "mm:ss.SSS"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    // Convert the time interval to a timestamp string.
    let date = Date(timeIntervalSince1970: timeInterval)
    return formatter.string(from: date)
}
