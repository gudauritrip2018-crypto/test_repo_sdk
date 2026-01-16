# AriseMobileSdk iOS Framework

## Project Structure

```
ios-sdk/
├── src/                              # Framework source code
│   ├── AriseMobileSdk/               # Framework implementation
│   │   └── AriseMobileSdk.swift      # Main SDK class
│   ├── AriseMobileSdk.xcodeproj/     # Xcode project
│   └── AriseTestAppForDebug/         # Test application (development)
│       ├── AriseTestAppForDebugApp.swift # App entry point
│       └── ContentView.swift         # Main UI
├── libs/                             # Built frameworks
│   ├── build_framework.sh            # Build script
│   ├── AriseMobileSdk.xcframework    # Built AriseMobileSdk framework
│   └── CloudCommerce.xcframework     # CloudCommerce SDK
└── README.md                         # This file
```

## Building the Framework

### Step 1: Normalize swagger.json (if using swagger.json)

If you're using `swagger.json` instead of `arise-api.yaml`, first normalize the schema names to avoid long class names:

```bash
cd src/AriseMobileSdk/OpenAPI
python3 scripts/normalize_swagger_schemas.py specs/swagger.json
```

This script will:
- Find all long .NET generic type names (e.g., `Contracts.Page`1[[...]]`)
- Rename them to shorter, readable names (e.g., `TransactionsPageResponse`)
- Update all `$ref` references throughout the file
- Create a backup of the original file

**Dry run mode** (to preview changes without modifying the file):
```bash
python3 scripts/normalize_swagger_schemas.py specs/swagger.json --dry-run
```

### Step 2: Generate OpenAPI Client

After normalizing (if needed), generate the OpenAPI client from the API specification using the automated generation script:

```bash
# From project root, run the generation script
./src/AriseMobileSdk/OpenAPI/scripts/generate_openapi.sh
```

The script will:
- Automatically normalize the JSON specification if needed
- Create the directory structure (`generated/`)
- Generate `Package.swift` with proper dependencies
- Create/update `openapi-generator-config.yaml` with `namingStrategy: idiomatic`
- Copy the specification file to the generated directory
- Run Swift OpenAPI Generator to create Swift code
- Copy generated files to `Networking/GeneratedSources/` for use in the project

**Using a custom OpenAPI specification file:**

```bash
# Generate from a custom file (generated code will be in the same directory as the spec file)
./src/AriseMobileSdk/OpenAPI/scripts/generate_openapi.sh /path/to/custom-api.yaml
```

**Note:** The OpenAPI client is generated automatically during build using Swift Package Manager plugin. The generated code is created in `DerivedData` during Xcode build. The generation script handles all the setup automatically.

**Alternative tools:** See [docs/OPENAPI_GENERATOR_ALTERNATIVES.md](docs/OPENAPI_GENERATOR_ALTERNATIVES.md) for information about Swift OpenAPI Generator (Apple) and other alternatives.

### Step 3: Build the Framework

Use the provided build script to create the XCFramework:

```bash
./libs/build_framework.sh
```

This script:
- Builds the framework for iOS device (arm64)
- Builds the framework for iOS simulator (arm64)
- Creates a universal XCFramework supporting both platforms
- Outputs the result to `libs/AriseMobileSdk.xcframework`

## Integration

### Adding to Your Project

1. **Copy the Framework**: Add `libs/AriseMobileSdk.xcframework` to your project
2. **Add CloudCommerce**: Include `libs/CloudCommerce.xcframework` in your project
3. **Add Dependencies**: Add the following Swift Package Manager dependencies:
   - `CryptoSwift` (https://github.com/krzyzanowskim/CryptoSwift.git)
   - `swift-asn1` (https://github.com/apple/swift-asn1.git)
   - `swift-certificates` (https://github.com/apple/swift-certificates.git)

### Basic Usage

```swift
import AriseMobileSdk

// Initialize the SDK
let sdk = AriseMobileSdk()

// Get CloudCommerce version
let cloudCommerceVersion = sdk.getCloudCommerceVersion()
print("CloudCommerce Version: \(cloudCommerceVersion)")

// Get AriseMobileSdk version
let ariseVersion = sdk.getAriseMobileSdkVersion()
print("AriseMobileSdk Version: \(ariseVersion)")
```

## Testing

Two test applications are available:

### TestAppArise Target

The `TestAppArise` target in `src/AriseMobileSdk.xcodeproj` is for development and debugging:
- Built together with the framework
- Uses the framework in development
- Quick iteration and debugging

### Test App (test-app/)

The standalone test app in `test-app/` is for testing the ready-built framework:

1. Open `test-app/AriseMobileSdkTestApp.xcodeproj`
2. Build and run the project
3. Test the integration with the built framework

## Dependencies

- **CloudCommerce.xcframework**: Core payment processing SDK
- **CryptoSwift**: Cryptographic functions
- **swift-asn1**: ASN.1 encoding/decoding
- **swift-certificates**: Certificate handling

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+


### Advanced CI/CD Configuration

#### Custom DerivedData Location

Override the DerivedData location for local testing:

```bash
export DERIVED_DATA_OVERRIDE=~/CustomDerivedData
./libs/test_ci.sh
```

#### Running Specific Tests

Run specific test classes or methods:

```bash
xcodebuild test \
  -project src/AriseMobileSdk.xcodeproj \
  -scheme AriseMobileSdk \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:AriseMobileSdkTests/TransactionsServiceTests
```

#### Complete GitHub Actions Workflow with Caching

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build-and-test:
    runs-on: macos-14
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app
    
    - name: Cache DerivedData
      uses: actions/cache@v3
      with:
        path: ios-sdk/DerivedData-Tests
        key: ${{ runner.os }}-deriveddata-${{ hashFiles('**/Package.resolved') }}
        restore-keys: |
          ${{ runner.os }}-deriveddata-
    
    - name: Build and Test
      run: |
        cd ios-sdk
        ./libs/build_and_test_ci.sh both
      
    - name: Upload Test Results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: ios-sdk/test-results.xcresult
    
    - name: Upload Framework
      if: success()
      uses: actions/upload-artifact@v3
      with:
        name: framework
        path: ios-sdk/libs/AriseMobile.xcframework
```

### Performance Tips

1. **Cache DerivedData** - Reuse compiled dependencies between builds
2. **Pre-compile SourcePackages** - Commit pre-compiled packages to speed up CI
3. **Parallel Jobs** - Run build and test in separate jobs for faster feedback
4. **Incremental Builds** - Only rebuild changed files

### Security Considerations

- Never commit sensitive credentials to CI scripts
- Use secrets management (GitHub Secrets, Jenkins Credentials)
- Sign frameworks with proper certificates in CI
- Validate code signing before distribution
