//
//  VideoManager.swift
//  VideoPlayerDemo
//
//  Created by Seungchul Ha on 3/11/22.
//

import Foundation

enum Query: String, CaseIterable {
    case nature, animals, people, ocean, food
}

class VideoManager: ObservableObject {
    @Published private(set) var videos: [Video] = []
    @Published var selectedQuery: Query = Query.nature {
        didSet {
            Task.init {
                await findVideos(topic: selectedQuery)
            }
        }
    }
    
    
    init() {
        Task.init{
            await findVideos(topic: selectedQuery)
        }
    }
    
    
    func findVideos(topic: Query) async {
        do {
            // Make sure we have a URL before continuing
            guard let url = URL(string: "https://api.pexels.com/videos/search?query=\(topic)&per_page=10&orientation=portrait") else { fatalError("Missing URL") }
            
            // Create a URLRequest
            var urlRequest = URLRequest(url: url)
            
            // Setting the Authorization header of the HTTP request - replace YOUR_API_KEY by your own API key
            urlRequest.setValue("YOUR_API_KEY", forHTTPHeaderField: "Authorization")
            
                // Fetching the data
                let (data, response) = try await URLSession.shared.data(for: urlRequest)
                
                // Making sure the response is 200 OK before continuing
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching data") }
                
                // Creating a JSONDecoder instance
                let decoder = JSONDecoder()
                
                // Allows us to convert the data from the API from snake_case to cameCase
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                // Decode into the ResponseBody struct below
                let decodedData = try decoder.decode(ResponseBody.self, from: data)
                
                // Setting the videos variable
                DispatchQueue.main.async {
                    // Reset the videos (for when we're calling the API again)
                    self.videos = []
                    
                    // Assigning the videos we fetched from the API
                    self.videos = decodedData.videos
                }
            
        } catch {
            print("Error fetching data from Pexels: \(error)")
        }
    }
}

struct ResponseBody: Decodable {
    var page: Int
    var perPage: Int
    var totalResults: Int
    var url: String
    var videos: [Video]
    
}

struct Video: Identifiable, Decodable {
    var id: Int
    var image: String
    var duration: Int
    var user: User
    var videoFiles: [VideoFile]
    
    struct User: Identifiable, Decodable {
        var id: Int
        var name: String
        var url: String
    }
    
    struct VideoFile: Identifiable, Decodable {
        var id: Int
        var quality: String
        var fileType: String
        var link: String
    }
}
