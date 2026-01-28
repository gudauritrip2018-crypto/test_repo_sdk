import Foundation

/// Authentication result containing access token and expiration info (internal use only)
internal struct AuthenticationResult {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String

    init(accessToken: String, refreshToken: String?, expiresIn: Int, tokenType: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
    }
}

