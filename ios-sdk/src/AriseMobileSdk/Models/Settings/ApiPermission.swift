import Foundation

/// API permission types
public enum ApiPermission: Int, Codable, Hashable, Sendable {
    case posStartTransaction = 0
    case posGetTransactions = 1
    case posGetTransactionDetails = 2
    case posCancelTransaction = 3
    case posPrintReceipt = 4
    case getTerminalList = 5
    case getTerminalInformation = 6
    case ecommerceAuth = 7
    case ecommerceSale = 8
    case ecommerceCapture = 9
    case ecommerceVoid = 10
    case ecommerceRefund = 11
    case ecommerceRefundWithoutReference = 12
    case achDebit = 13
    case achCredit = 14
    case achVoid = 15
    case achHold = 16
    case achUnhold = 17
    case listTransactions = 18
    case getTransactionDetails = 19
    case calculateTransactionAmount = 20
    case submitTipAdjustment = 21
    case getSettlementBatches = 22
    case submitBatchForSettlement = 23
    case sendReceiptBySms = 24
    case listCustomers = 25
    case getCustomerDetails = 26
    case manageCustomers = 27
    case hostedInvoices = 28
    case hostedQuickPayment = 29
    case hostedSubscriptions = 30
    case hostedWebComponents = 31
    case hostedWooCommerce = 32
    case featureTapToPayOnMobile = 33
    case generalPing = 34
    case generalStatus = 35
    case generalConfigurations = 36
}
