import Foundation

/// Refund transaction request parameters
///
/// Represents the data required to submit a refund (return) against a settled transaction.
/// Supports both full and partial refunds and allows passing additional card-present metadata when required.
/// 
/// - Note: This is an internal structure used by the SDK. External developers should use the public `refundTransaction(transactionId:amount:)` method.
internal struct RefundRequest {
    /// Identifier of the transaction to refund
    let transactionId: String

    /// Amount to refund. When `nil`, the API will attempt to refund the remaining refundable balance.
    let amount: Double?

    /// Card data source that describes how the refund is initiated (manual, swipe, etc.)
    /// When `nil`, defaults to `.internet` (card-not-present) when sent to the API.
    let cardDataSource: CardDataSource?

    /// Track 1 magnetic stripe data (optional, card-present scenarios)
    let track1: String?

    /// Track 2 magnetic stripe data (optional, card-present scenarios)
    let track2: String?

    /// EMV tags collected during the refund (optional)
    let emvTags: [String]?

    /// EMV payment application version (optional)
    let emvPaymentAppVersion: String?

    /// Encrypted PIN block (optional, for debit refunds)
    let pin: String?

    /// Key serial number associated with the encrypted PIN (optional)
    let pinKsn: String?

    /// Creates a new refund request
    /// - Parameters:
    ///   - transactionId: Identifier of the original transaction to refund
    ///   - amount: Amount to refund (optional for full refunds)
    ///   - cardDataSource: Data source describing how the refund is captured (manual, swipe, etc.). When `nil`, defaults to `.internet` (card-not-present) when sent to the API.
    ///   - track1: Optional track 1 data
    ///   - track2: Optional track 2 data
    ///   - emvTags: Optional EMV tags array
    ///   - emvPaymentAppVersion: Optional EMV application version
    ///   - pin: Optional encrypted PIN
    ///   - pinKsn: Optional PIN key serial number
    init(
        transactionId: String,
        amount: Double? = nil,
        cardDataSource: CardDataSource? = nil,
        track1: String? = nil,
        track2: String? = nil,
        emvTags: [String]? = nil,
        emvPaymentAppVersion: String? = nil,
        pin: String? = nil,
        pinKsn: String? = nil
    ) {
        self.transactionId = transactionId
        self.amount = amount
        self.cardDataSource = cardDataSource
        self.track1 = track1
        self.track2 = track2
        self.emvTags = emvTags
        self.emvPaymentAppVersion = emvPaymentAppVersion
        self.pin = pin
        self.pinKsn = pinKsn
    }
}


