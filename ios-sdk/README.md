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

- iOS 18.0+
- Xcode 15.0+
- Swift 5.9+


## CI/CD Pipeline

| Branch | Release Type | Version Example |
|--------|-------------|-----------------|
| `main` | Pre-release | `v2.0.0-pre-release-5` |
| `release/X.Y.Z` | Production | `v2.0.0` |

### Pre-release (main branch)

Every push to `main` creates a pre-release automatically:
- Version format: `{plist_version}-pre-release-{build_number}`
- Build number increments based on previous tags
- Only last 5 pre-releases are kept, older ones are deleted

### Production Release

To create a production release:

1. Create and push a branch with format `release/X.Y.Z`:
   ```bash
   git checkout -b release/2.0.0
   git push origin release/2.0.0
   ```

2. (Optional) Add release notes file:
   ```bash
   # Create ios-sdk/RELEASE_NOTES.md with your changes
   git add ios-sdk/RELEASE_NOTES.md
   git commit -m "Add release notes for v2.0.0"
   git push origin release/2.0.0
   ```

3. **Manually trigger** the workflow:
   - Go to Actions → "Deploy iOS SDK Release"
   - Click "Run workflow"
   - Select branch `release/X.Y.Z`
   - (Optional) Specify path to release notes file, or leave empty for auto-generated changelog
   - Click "Run workflow"

4. The workflow will:
   - Build the SDK
   - Push to `release` branch in distribution repo
   - Create a production release with tag `vX.Y.Z`

### Release Notes

Release notes can be provided via `ios-sdk/RELEASE_NOTES.md` file (markdown supported):

```markdown
### New Features
- Added new payment method support
- Improved TTP compatibility checks

### Bug Fixes
- Fixed timeout issue in authentication

### Breaking Changes
- Changed `authenticate()` method signature
```

#### Auto-generated Changelog

If `RELEASE_NOTES.md` doesn't exist, the workflow automatically generates a changelog:

| Release Type | Changelog Source |
|--------------|------------------|
| **Production** (`release/X.Y.Z`) | Commits since the last production release tag |
| **Pre-release** (`main`) | Commits since the last pre-release tag |

The auto-generated changelog includes all commits in `ios-sdk/` folder since the previous release, formatted as:
```
- Commit message (abc1234)
- Another commit message (def5678)
```

> **Note:** If no previous releases exist, the last 20 commits are used as fallback.

### Breaking Changes (Major Version Update)

When introducing breaking changes, update the major version in Info.plist:

1. Open `src/AriseMobileSdk/AriseMobileSdk-Info.plist`
2. Update `CFBundleShortVersionString` to the new major version (e.g., `2.0.0`)
3. Commit and push

The CI workflow will automatically detect that the plist major version is higher than the current tags and use it as the new baseline.

### GitHub Setup

1. **Create distribution repository** (empty repo for SPM distribution)

2. **Create GitHub App**

   GitHub App provides better security with scoped permissions and automatic token rotation.

   **Step 1: Create GitHub App**
   - Go to GitHub → Settings → Developer settings → GitHub Apps → New GitHub App
   - App name: `iOS SDK Distribution Bot`
   - Homepage URL: `https://github.com/aurora-payments/arise-merchant-app`
   - Uncheck "Webhook" → Active
   - Permissions → Repository permissions:
     - Contents: **Read and write**
     - Metadata: **Read-only**
   - Where can this app be installed: **Only on this account**
   - Click "Create GitHub App"

   **Step 2: Get App ID**
   - After creation, you'll see the App settings page
   - **App ID** is displayed at the top (e.g., `1234567`)
   - Copy this value for `DISTRIBUTION_APP_ID` secret

   **Step 3: Generate Private Key**
   - On the same App settings page, scroll down to **"Private keys"** section
   - Click **"Generate a private key"**
   - A `.pem` file will be downloaded automatically (e.g., `ios-sdk-distribution-bot.2024-01-15.private-key.pem`)
   - Open the file in a text editor
   - Copy the **entire content** including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`
   - This is your `DISTRIBUTION_APP_PRIVATE_KEY` secret value

   **Step 4: Install the App**
   - Go to GitHub App settings → Install App
   - Select `aurora-payments` organization
   - Choose "Only select repositories"
   - Select only `arise-mobile-ios-sdk` repository
   - Click Install

   **Step 5: Add secrets to source repository**

   Go to `arise-merchant-app` repo → Settings → Secrets and variables → Actions → New repository secret

   | Secret                         | Value                                  | Description                |
   |--------------------------------|----------------------------------------|----------------------------|
   | `DISTRIBUTION_APP_ID`          | `1234567`                              | GitHub App ID from Step 2  |
   | `DISTRIBUTION_APP_PRIVATE_KEY` | `-----BEGIN RSA PRIVATE KEY-----...`   | Full .pem file content     |
   | `DISTRIBUTION_REPO`            | `aurora-payments/arise-mobile-ios-sdk` | Full repo path             |
   | `DISTRIBUTION_REPO_OWNER`      | `aurora-payments`                      | Organization name          |
   | `DISTRIBUTION_REPO_NAME`       | `arise-mobile-ios-sdk`                 | Repository name only       |

3. **Enable Actions** (Settings → Actions → General):
   - Allow all actions
   - Workflow permissions: Read and write

### Distribution Folder Structure

```
Distribution/
├── Package.swift    # SPM package manifest (copied to distribution repo)
├── README.md        # SDK documentation for distribution repo
├── Sources/         # Swift wrapper files for SPM
│   └── ARISEMobileSDK/
└── libs/            # Built XCFrameworks (created by CI)
```

| File | Purpose |
|------|---------|
| `Package.swift` | Defines SPM package, dependencies, and binary targets |
| `Sources/` | Minimal Swift files required by SPM package structure |
| `libs/` | Contains built `.xcframework` files (populated during CI build) |

---

## SDK Integration (SPM)

**Production** (auto-updates):
```swift
.package(url: "https://github.com/your-org/sdk-distribution.git", from: "1.0.0")
```

**UAT** (fixed version):
```swift
.package(url: "https://github.com/your-org/sdk-distribution.git", exact: "1.0.1-uat")
```

In Xcode: File → Add Package Dependencies → select version rule.

---

## Local Development

```bash
./libs/build_framework.sh          # Build XCFramework
./libs/build_and_test_ci.sh test   # Run tests
./libs/build_and_test_ci.sh both   # Build and test
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Swift version mismatch | Use `runs-on: macos-15` for Xcode 16.4+ |
| CloudCommerce not found | Commit `CloudCommerce.xcframework` to git |
| Workflow doesn't trigger | Check changes are in `ios-sdk/` directory |
