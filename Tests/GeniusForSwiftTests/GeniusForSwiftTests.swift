import XCTest
@testable import GeniusForSwift

final class GeniusForSwiftTests: XCTestCase {
    @available(iOS 13.0.0, *)
    func testExample() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        //XCTAssertEqual(GeniusForSwift().text, "Hello, World!")
        let options = GeniusOptions(title: "", artist: "Kendrick Lamar", apiKey: "")
        
        do {
            let songs = try await searchSong(options)
        } catch {
            print(error.localizedDescription)
        }
    }
}
