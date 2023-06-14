//
//  APIClient.swift
//
//
//  Created by iwashita on 2023/06/14.
//

import Foundation

public enum APIClientError: Error, LocalizedError {
    case invalidURL
    case responseError
    case parseError(Error)
    case serverError(Error)
    case badStatus(statusCode: Int)
    case noData
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .responseError:
            return "API response error"
        case .parseError(_):
            return "Parse error"
        case .serverError(_):
            return "Server error"
        case .badStatus(statusCode: let statusCode):
            return "Bad status (\(statusCode))"
        case .noData:
            return "No data"
        }
    }
}
