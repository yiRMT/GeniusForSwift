import Foundation

func getTitle(title: String, artist: String) -> String {
    let str = "\(title) \(artist)".lowercased().replacingOccurrences(of: #" *\([^)]*\) *"#, with: "", options: .regularExpression).replacingOccurrences(of: #" *\[[^\]]*]"#, with: "", options: .regularExpression).replacingOccurrences(of: #"feat.|ft."#, with: "", options: .regularExpression).replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    return str
}

@available(iOS 13.0.0, *)
public func getAlbumArt(_ options: GeniusOptions) async throws -> String? {
    do {
        let results = try await searchSong(options)
        if (results == nil) {
            return nil
        }
        return results?[0].song_art_image_url
    } catch {
        throw error
    }
}
    
///
/// - Parameter options: Genius options
/// - Returns: returns an array of search results. returns null if no matches are found
@available(iOS 13.0.0, *)
public func searchSong(_ options: GeniusOptions) async throws -> [GeniusSearchResult]? {
    let song = options.optimizeQuery! ? getTitle(title: options.title, artist: options.artist) : "\(options.title) \(options.artist)"
    let searchURL = "https://api.genius.com/search?q="
    let requestURL = searchURL + song.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)! + "&access_token=\(options.apiKey)"
    
    print(requestURL)
    
    guard let url = URL(string: requestURL) else {
        throw APIClientError.invalidURL
    }
    
    do {
        let (data, urlResponse) = try await URLSession.shared.data(from: url)
        
        guard let httpStatus = urlResponse as? HTTPURLResponse else {
            throw APIClientError.responseError
        }
        
        switch httpStatus.statusCode {
        case 200 ..< 400:
            guard let decoderResponse = try? JSONDecoder().decode(GeniusSearch.self, from: data) else {
                throw APIClientError.noData
            }
            let hits = decoderResponse.response.hits
            
            if hits.count == 0 {
                return nil
            }
            
            return hits.map { $0.result }
        case 400...:
            throw APIClientError.badStatus(statusCode: httpStatus.statusCode)
        default:
            fatalError()
            break
        }
    } catch {
        throw error
    }
}

public struct GeniusOptions {
    var title: String
    var artist: String
    var apiKey: String  // Genius developer access token
    var optimizeQuery: Bool? = false
}

struct GeniusSearch: Codable {
    var meta: Meta
    public struct Meta: Codable {
        var status: Int
    }
    var response: Response
    struct Response: Codable {
        var hits: [Hit]
        struct Hit: Codable {
            var result: GeniusSearchResult
        }
    }
}

public struct GeniusSearchResult: Codable {
    var id: Int             // Genius song id
    var url: String         // Genius webpage URL for the song
    var title: String       // Song title
    var song_art_image_url: String    // URL of the album art image (jpg/png)
}
