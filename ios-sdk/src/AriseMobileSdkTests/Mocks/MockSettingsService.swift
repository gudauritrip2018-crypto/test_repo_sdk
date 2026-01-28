import Foundation
@testable import ARISE

/// Mock implementation of SettingsServiceProtocol for testing
final class MockSettingsService: SettingsServiceProtocol {
    // MARK: - Configuration
    
    var paymentSettingsResult: Result<PaymentSettingsResponse, Error> = .success(
        PaymentSettingsResponse(
            availableCurrencies: [],
            zeroCostProcessingOptionId: nil,
            zeroCostProcessingOption: nil,
            defaultSurchargeRate: nil,
            defaultCashDiscountRate: nil,
            defaultDualPricingRate: nil,
            isTipsEnabled: false,
            defaultTipsOptions: nil,
            availableCardTypes: [],
            availableTransactionTypes: [],
            availablePaymentProcessors: [],
            avs: nil,
            companyName: "Mock Company",
            mccCode: "1234",
            currencyCode: "USD",
            currencyId: 1,
            countryCode: "USA"
        )
    )
    
    var permissionsResult: Result<ApiPermissionsResponse, Error> = .success(
        ApiPermissionsResponse(
            permissions: [
                .featureTapToPayOnMobile,
                .listTransactions,
                .getTransactionDetails
            ]
        )
    )
    
    // MARK: - Call Tracking
    
    private(set) var getPaymentSettingsCallCount = 0
    private(set) var getPermissionsCallCount = 0
    
    // MARK: - Initialization
    
    init() {
        // Mock doesn't need initialization - all methods are mocked
    }
    
    // MARK: - SettingsServiceProtocol Implementation
    
    func getPaymentSettings() async throws -> PaymentSettingsResponse {
        getPaymentSettingsCallCount += 1
        
        switch paymentSettingsResult {
        case .success(let settings):
            return settings
        case .failure(let error):
            throw error
        }
    }
    
    func getPermissions() async throws -> ApiPermissionsResponse {
        getPermissionsCallCount += 1
        
        switch permissionsResult {
        case .success(let permissions):
            return permissions
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        getPaymentSettingsCallCount = 0
        getPermissionsCallCount = 0
    }
}

