import Foundation
import OpenAPIRuntime
import HTTPTypes

/// Shared storage for buffered response body data between middleware
/// This allows ResponseLoggingMiddleware to buffer the body and ErrorHandlingMiddleware
/// to access it without re-reading (which causes fatal errors)
internal actor ResponseBodyBuffer {
    private var bufferedData: [String: Data] = [:]
    
    func set(operationID: String, data: Data?) {
        bufferedData[operationID] = data
    }
    
    func get(operationID: String) -> Data? {
        return bufferedData[operationID]
    }
    
    func clear(operationID: String) {
        bufferedData.removeValue(forKey: operationID)
    }
}

/// Global buffer instance (shared between middleware instances)
internal let responseBodyBuffer = ResponseBodyBuffer()

/// Middleware for logging raw HTTP response bodies at VERBOSE level
internal struct ResponseLoggingMiddleware: ClientMiddleware, @unchecked Sendable {
    let logger: AriseLogger
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let (response, responseBody) = try await next(request, body, baseURL)
        
        // Log raw response at VERBOSE level
        logger.verbose("═══════════════════════════════════════════════════")
        logger.verbose("📥 Raw HTTP Response")
        logger.verbose("═══════════════════════════════════════════════════")
        logger.verbose("Operation: \(operationID)")
        logger.verbose("Status Code: \(response.status.code)")
        logger.verbose("Headers: \(response.headerFields)")
        logger.verbose("Response Body: (not read to avoid fatal stream errors)")
        logger.verbose("Note: Response body streams can only be read once and must be consumed by client code.")
        logger.verbose("═══════════════════════════════════════════════════")

        // Store nil in buffer (body not read to avoid stream errors)
        await responseBodyBuffer.set(operationID: operationID, data: nil)

        // Return response with original body
        return (response, responseBody)
    }
}

