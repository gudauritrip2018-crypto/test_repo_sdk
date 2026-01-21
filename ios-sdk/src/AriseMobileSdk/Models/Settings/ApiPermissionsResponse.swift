import Foundation

/// Response containing list of enabled API permissions
public struct ApiPermissionsResponse: Codable, Hashable, Sendable {
    /// List of enabled API permissions
    public let permissions: [ApiPermission]
    
    public init(permissions: [ApiPermission]) {
        self.permissions = permissions
    }
}
