# ARISE Mobile SDK for iOS

Official iOS SDK for ARISE Payment Platform - enables Tap to Pay on iPhone and payment processing capabilities.

## Requirements

- iOS 18.0+
- Xcode 15.0+
- Swift 5.9+
- **Physical iPhone XS or later** (Tap to Pay is not supported on simulators)
- [Apple Sandbox Account](https://developer.apple.com/help/app-store-connect/test-in-app-purchases/create-a-sandbox-apple-account/) for testing

> **Important:** Payment transactions work only on physical iOS devices and are not supported on simulators.

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

## Configuration

### Info.plist

Add the following keys to your app's `Info.plist`:

```xml
<key>PRODUCT_TEAM_IDENTIFIER</key>
<string>YOUR_TEAM_ID</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required for Tap to Pay functionality</string>
```

> **Note:** `PRODUCT_TEAM_IDENTIFIER` is your Apple Team ID required for SDK attestation. You can find it in [Apple Developer](https://developer.apple.com/account) under **"Membership details"** or in **"Certificates, Identifiers & Profiles"** section.

### Signing & Capabilities

In Xcode, add the required capabilities for Tap to Pay:

1. Select your app target
2. Go to **Signing & Capabilities** tab
3. Click **"+ Capability"** and add:
   - **"Tap to Pay on iPhone"** — see [Apple Developer Documentation](https://developer.apple.com/documentation/proximityreader/setting-up-the-entitlement-for-tap-to-pay-on-iphone)
   - **"NFC Scan"**

This will automatically:
- Create an entitlements file with `com.apple.developer.proximity-reader.payment.acceptance`
- Add NFC entitlement for card reading
- Update your provisioning profile

> **Important:** Tap to Pay capability requires **prior approval from Apple**.
>
> 1. Request access at [developer.apple.com/contact/request/tap-to-pay-on-iphone](https://developer.apple.com/contact/request/tap-to-pay-on-iphone/)
> 2. Fill out the form with your company and app information
> 3. Wait for Apple's approval (this may take time)
> 4. After approval, the capability will appear in your Developer Portal
>
> Without Apple's approval, you will see the error: *"Entitlement com.apple.developer.proximity-reader.payment.acceptance not found"*

### ProximityReader Framework

Add Apple's ProximityReader framework to your project:

1. Select your app target
2. Go to **Build Phases** tab
3. Expand **"Link Binary With Libraries"**
4. Click **"+"** and add `ProximityReader.framework`

For more information, see [Apple ProximityReader Documentation](https://developer.apple.com/documentation/proximityreader).

### Location Permission Requirement

**Important:** Tap to Pay on iPhone requires location permission to be **granted** by the user.

- Grant location permission and enable GPS in your app
- The recommended setting is `CLAuthorizationStatus.authorizedWhenInUse`
- User must **accept** the location permission dialog
- If permission is denied, Tap to Pay functionality will not work

```swift
// Check if location permission is granted
let result = sdk.ttp.checkCompatibility()
if result.locationPermission != .granted {
    // Request location permission from user
    locationManager.requestWhenInUseAuthorization()
}
```

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

// Check Tap to Pay compatibility
let compatibility = sdk.ttp.checkCompatibility()
if compatibility.isCompatible {
    // Activate Tap to Pay
    try await sdk.ttp.activate()

    // Prepare for transaction
    try await sdk.ttp.prepare()

    // Perform transaction
    let result = try await sdk.ttp.performTransaction(amount: 10.00)
}
```

## Features

- **Tap to Pay on iPhone** - Accept contactless payments
- **Payment Processing** - Sales, refunds, voids
- **Transaction History** - Search and retrieve transactions
- **Device Management** - Register and manage terminals

## License

Copyright © ARISE Payments. All rights reserved.
