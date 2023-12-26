
import SwiftUI
import Foundation

struct SearchResultItem: Identifiable {
    var id: String
    var title: String
    var artist: String
    //    var duration: String
    var album: String
}

struct SearchResult: Decodable {
    var result: Result
}

struct Result: Decodable {
    var songs: [Song]
}

struct Song: Decodable {
    var id: Int
    var name: String
    var artists: [Artist]
    //    var duration: Int
    var album: Album
}

struct Artist: Decodable {
    var name: String
}

struct Album: Decodable {
    var name: String
}


func searchSong(keyword: String, completion: @escaping (Result?, Error?) -> Void) {
    
    guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        print("Error: Unable to encode keyword")
        return
    }
    
    let apiUrl = "https://music.163.com/api/search/get?s=\(encodedKeyword)&type=1&limit=30"
    
    guard let url = URL(string: apiUrl) else {
        print("Invalid URL")
        return
    }
    
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let data = data else {
            print("No data received")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let searchResult = try decoder.decode(SearchResult.self, from: data)
            completion(searchResult.result, nil)
        } catch {
            print("Error decoding JSON: \(error)")
            completion(nil, error)
        }
    }
    task.resume()
}


struct SubWindowView: View {
    
    var onClose: (() -> Void)
    @State var searchText: String = ""
    @State var searchResults: [SearchResultItem]  = []
    @State var selectedItemId: String?
    
    @State private var selection : SearchResult.Type?
    
    
    var body: some View {
        VStack {
            HStack {
                TextField("Enter search keyword", text: $searchText)
                Button("Search") {
                    searchSong (keyword: searchText) { result, error in
                        if let error = error {
                            print("Error: \(error)")
                            return
                        }
                        if let songs = result?.songs {
                            DispatchQueue.main.async {
                                self.searchResults = songs.map {
                                    SearchResultItem(id: "\($0.id)", title: $0.name, artist: $0.artists.first?.name ?? "Unknown Artist", album: $0.album.name) //duration: "\($0.duration)ms"
                                }
                            }
                        }
                    }
                }
            }
            
            Table(searchResults, selection: $selectedItemId) {
                TableColumn("Title", value: \.title)
                TableColumn("Artist", value: \.artist)
                //                TableColumn("Duration", value: \.duration)
                TableColumn("Album", value: \.album)
                //                TableColumn("ID", value: \.id )
            }
            
            .contextMenu(forSelectionType: SearchResultItem.ID.self
            ) { items in
            } primaryAction: { items in
                print(items)
                // This is executed when the row is double clicked
            }
            .border(Color.gray, width: 1)
        }
        .padding()
        .onDisappear {
            onClose()
            print("Sub window closed")
        }
    }
}
