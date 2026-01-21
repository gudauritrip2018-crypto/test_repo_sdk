import Foundation

class SettingsService: BaseApiClient, SettingsServiceProtocol, @unchecked Sendable {
    
    init(tokenService: TokenService, environmentSettings: EnvironmentSettings) {
        super.init(
            tokenService: tokenService,
            environmentSettings: environmentSettings,
            queueLabel: "com.arise.mobile.sdk.settings.api.config"
        )
    }
    
    func getPaymentSettings() async throws -> PaymentSettingsResponse {
        let client = try getApiClient()
        
        do {
            let generatedResult = try await client.getPayApiV1ConfigurationsPayments(.init())
            let result = try PaymentSettingsResponseMapper.toModel(generatedResult)
            
            return result
        } catch {
            try DecodingErrorHandler().handleError(error)
            throw error
        }
    }
    
    func getPermissions() async throws -> ApiPermissionsResponse {
        let client = try getApiClient()
        
        do {
            let generatedResult = try await client.getApiAvailableApiPermissions(.init())
            let result = try ApiPermissionsResponseMapper.toModel(generatedResult)
            
            return result
        } catch {
            try DecodingErrorHandler().handleError(error)
            throw error
        }
    }
}

