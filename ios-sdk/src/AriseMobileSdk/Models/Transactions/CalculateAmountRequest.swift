import Foundation

/// Request parameters for calculating a transaction amount prior to submission.
///
/// Supply the base amount, currency, and any optional modifiers to obtain the final totals that will be
/// presented to the customer under the current Zero Cost Processing configuration.
public struct CalculateAmountRequest {
    /// Base transaction amount before any discounts or surcharges.
    public let amount: Double

    /// Currency identifier (matches PaymentGateway currency identifiers such as `1` for USD). Defaults to `1` (USD).
    public let currencyId: Int32

    /// Percentage-off or discount rate (e.g. `5.0` for a 5% discount).
    public let percentageOffRate: Double?

    /// Surcharge rate to apply (e.g. `3.0` for a 3% surcharge).
    public let surchargeRate: Double?

    /// Absolute tip amount to add on top of the base amount.
    public let tipAmount: Double?

    /// Tip rate expressed as percentage (e.g. `10.0` for a 10% gratuity).
    public let tipRate: Double?

    public init(
        amount: Double,
        currencyId: Int32 = 1,
        percentageOffRate: Double? = nil,
        surchargeRate: Double? = nil,
        tipAmount: Double? = nil,
        tipRate: Double? = nil
    ) {
        self.amount = amount
        self.currencyId = currencyId
        self.percentageOffRate = percentageOffRate
        self.surchargeRate = surchargeRate
        self.tipAmount = tipAmount
        self.tipRate = tipRate
    }
}


