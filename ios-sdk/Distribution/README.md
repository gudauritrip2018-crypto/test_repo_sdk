# ARISE Mobile SDK for iOS

Official iOS SDK for ARISE Payment Platform - enables Tap to Pay on iPhone and payment processing capabilities.

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+
- iPhone XS or later (for Tap to Pay)

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aurora-payments/arise-mobile-ios-sdk.git", from: "1.0.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "ARISEMobileSDK", package: "arise-mobile-ios-sdk")
    ]
)
```

### Xcode

1. File → Add Package Dependencies
2. Enter: `https://github.com/aurora-payments/arise-mobile-ios-sdk.git`
3. Select version rule (e.g., "Up to Next Major Version")
4. Click "Add Package"

## Quick Start

```swift
import ARISEMobileSDK

// Initialize SDK
let sdk = try AriseMobileSdk(environment: .production)

// Authenticate
try await sdk.authenticate(
    clientId: "your-client-id",
    clientSecret: "your-client-secret"
)

// Get payment settings
let settings = try await sdk.getPaymentSettings()

// Process payment with Tap to Pay
let result = try await sdk.processPayment(
    amount: 10.00,
    currency: "USD"
)
```

## Features

- **Tap to Pay on iPhone** - Accept contactless payments
- **Payment Processing** - Sales, refunds, voids
- **Transaction History** - Search and retrieve transactions
- **Device Management** - Register and manage terminals

## License

Copyright © ARISE Payments. All rights reserved.
