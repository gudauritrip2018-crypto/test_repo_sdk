import Foundation

/// Transaction creation method identifier
/// 
/// Represents the method used to create a transaction.
/// 
public enum CreateMethodId: Int, CaseIterable {
    /// Portal
    case portal = 1
    
    /// API Token
    case apiToken = 2
    
    /// Terminal
    case terminal = 3
    
    /// Invoice
    case invoice = 4
    
    /// Quick Payment
    case quickPayment = 5
    
    /// Web Component
    case webComponent = 6
    
    /// Subscription
    case subscription = 7
    
    /// Mobile App
    case mobileApp = 8
    
    /// Tap to Pay
    case tapToPay = 9
    
    /// Human-readable name for the creation method
    public var displayName: String {
        switch self {
        case .portal:
            return "Portal"
        case .apiToken:
            return "API Token"
        case .terminal:
            return "Terminal"
        case .invoice:
            return "Invoice"
        case .quickPayment:
            return "Quick Payment"
        case .webComponent:
            return "Web Component"
        case .subscription:
            return "Subscription"
        case .mobileApp:
            return "Mobile App"
        case .tapToPay:
            return "Tap to Pay"
        }
    }
}
