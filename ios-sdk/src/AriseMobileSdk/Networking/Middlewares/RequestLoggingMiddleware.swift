import Foundation
import OpenAPIRuntime
import HTTPTypes

/// Middleware for logging HTTP request details at VERBOSE level
internal struct RequestLoggingMiddleware: ClientMiddleware, @unchecked Sendable {
    let logger: AriseLogger
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        // Log request details at VERBOSE level
        logger.verbose("═══════════════════════════════════════════════════")
        logger.verbose("📤 HTTP Request")
        logger.verbose("═══════════════════════════════════════════════════")
        
        // Build full URL
        let fullURL = baseURL.appendingPathComponent(request.path ?? "")
        logger.verbose("🌐 URL: \(fullURL.absoluteString)")
        logger.verbose("📋 Method: \(request.method.rawValue)")
        
        // Log headers (mask Authorization token)
        if !request.headerFields.isEmpty {
            var headersString = "📋 Headers:\n"
            for field in request.headerFields.sorted(by: { $0.name.canonicalName < $1.name.canonicalName }) {
                let key = field.name.canonicalName
                let value = field.value
                if key.lowercased() == "authorization" {
                    let maskedValue = value.prefix(20) + "..."
                    headersString += "   \(key): \(maskedValue)\n"
                } else {
                    headersString += "   \(key): \(value)\n"
                }
            }
            logger.verbose(headersString.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        let bodyToPass: HTTPBody?
        if let body = body {
            do {
                // Try to read body data for logging
                // HTTPBody returns ArraySlice<UInt8> chunks
                var bodyData = Data()
                for try await chunk in body {
                    bodyData.append(contentsOf: chunk)
                }
                
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    logger.verbose("📦 Body: \(bodyString)")
                } else {
                    logger.verbose("📦 Body: (binary data, \(bodyData.count) bytes)")
                }
                
                // Recreate body from data to pass through
                bodyToPass = HTTPBody(bodyData)
            } catch {
                logger.verbose("📦 Body: (error reading body: \(error.localizedDescription))")
                bodyToPass = body
            }
        } else {
            logger.verbose("📦 Body: (nil)")
            bodyToPass = nil
        }
        
        logger.verbose("═══════════════════════════════════════════════════")
        
        // Pass body through (recreated if it was read for logging)
        return try await next(request, bodyToPass, baseURL)
    }
}

