import Foundation

func getTitle(title: String, artist: String) -> String {
    let str = "\(title) \(artist)".lowercased().replacingOccurrences(of: #" *\([^)]*\) *"#, with: "", options: .regularExpression).replacingOccurrences(of: #" *\[[^\]]*]"#, with: "", options: .regularExpression).replacingOccurrences(of: #"feat.|ft."#, with: "", options: .regularExpression).replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    return str
}

/// Get the best match album art from keyword
/// - Parameter options: Genius options
/// - Throws: Throws HTTP errors
/// - Returns: URL for the album artwork
@available(iOS 13.0.0, *)
public func getAlbumArt(_ options: GeniusOptions) async throws -> String? {
    do {
        let results = try await searchSong(options)
        if (results == nil) {
            return nil
        }
        return results?[0].albumArt
    } catch {
        throw error
    }
}

/// Get the best match song from keyword
/// - Parameter options: Genius options
/// - Throws: Throws HTTP errors
/// - Returns: GenusSong
@available(iOS 13.0.0, *)
public func getSong(_ options: GeniusOptions) async throws -> GeniusSong? {
    do {
        let results = try await searchSong(options)
        if (results == nil) {
            return nil
        }
        return GeniusSong(id: results![0].id, title: results![0].title, url: results![0].url, albumArt: results![0].albumArt)
    } catch {
        throw error
    }
}

/// Get song data by song id
/// - Parameters:
///   - id: Genius song id
///   - apiKey: Genius API Key
/// - Throws: Throws HTTP errors
/// - Returns: GeniusSong
@available(iOS 13.0.0, *)
public func getSongById(id: Int, apiKey: String) async throws -> GeniusSong? {
    let searchURL = "https://api.genius.com/songs/"
    let requestURL = "\(searchURL)\(id)?access_token=\(apiKey)"
    
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
            guard let decoderResponse = try? JSONDecoder().decode(GeniusSongResponse.self, from: data) else {
                throw APIClientError.noData
            }
            let song = decoderResponse.response.song
            return GeniusSong(id: song.id, title: song.title, url: song.url, albumArt: song.song_art_image_url)
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
    
///Search songs by keywords
/// - Parameter options: Genius options
/// - Returns: returns an array of search results. returns null if no matches are found
@available(iOS 13.0.0, *)
public func searchSong(_ options: GeniusOptions) async throws -> [GeniusSearchResult]? {
    let song = options.optimizeQuery! ? getTitle(title: options.title, artist: options.artist) : "\(options.title) \(options.artist)"
    let searchURL = "https://api.genius.com/search?q="
    let requestURL = searchURL + song.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)! + "&access_token=\(options.apiKey)"
        
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
            guard let decoderResponse = try? JSONDecoder().decode(GeniusSearchResponse.self, from: data) else {
                throw APIClientError.noData
            }
            let hits = decoderResponse.response.hits
            
            if hits.count == 0 {
                return nil
            }
            
            let result = hits.map { (value) -> GeniusSearchResult in
                return GeniusSearchResult(id: value.result.id, url: value.result.url, title: value.result.title, albumArt: value.result.song_art_image_url)
            }
            
            return result
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

/// Option values for requests
public struct GeniusOptions {
    var title: String
    var artist: String
    var apiKey: String  // Genius developer access token
    var optimizeQuery: Bool? = false
}

/// Response format for requesting songs data
struct GeniusSongResponse: Codable {
    var meta: Meta
    public struct Meta: Codable {
        var status: Int
    }
    var response: Response
    struct Response: Codable {
        var song: Song
        struct Song: Codable {
            var id: Int
            var url: String
            var title: String
            var song_art_image_url: String
        }
    }
}

/// Response format for searching songs
struct GeniusSearchResponse: Codable {
    var meta: Meta
    public struct Meta: Codable {
        var status: Int
    }
    var response: Response
    struct Response: Codable {
        var hits: [Hit]
        struct Hit: Codable {
            var result: Result
            struct Result: Codable {
                var id: Int
                var url: String
                var title: String
                var song_art_image_url: String
            }
        }
    }
}

public struct GeniusSearchResult {
    var id: Int             // Genius song id
    var url: String         // Genius webpage URL for the song
    var title: String       // Song title
    var albumArt: String    // URL of the album art image (jpg/png)
}

public struct GeniusSong {
    var id: Int             // Genius song id
    var title: String       // Song title
    var url: String         // Genius webpage URL for the song
    var albumArt: String    // URL of the album art image (jpg/png)
}
