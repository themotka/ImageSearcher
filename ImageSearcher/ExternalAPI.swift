//
//  ExternalAPI.swift
//  ImageSearcher
//
//  Created by Matthew Widemann on 18.12.2024.
//

import Foundation

// MARK: - UnsplashPhotoModel

struct APIModel: Codable {
    let id: String
    let description: String?
    let urls: Urls
    let user: User
}

struct Urls: Codable {
    let regular: String
    let full: String
}

struct User: Codable {
    let name: String
}

final class APIService {
    private let accessKey = "IAbsrgym422ExMhoJmBWvBVmdJwiuhgjRQczqR7F8qw"
    private let baseUrl = "https://api.unsplash.com/"
    
    func searchPhotos(query: String, completion: @escaping (Result<[APIModel], Error>) -> Void) {
        let urlString = "\(baseUrl)search/photos?query=\(query)&per_page=30&client_id=\(accessKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            do {
                let result = try JSONDecoder().decode(SearchResult.self, from: data)
                completion(.success(result.results))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

struct SearchResult: Codable {
    let results: [APIModel]
}
