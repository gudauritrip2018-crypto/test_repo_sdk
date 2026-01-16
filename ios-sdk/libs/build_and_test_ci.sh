#!/bin/bash

# Combined build and test script for CI/CD
# Usage: ./build_and_test_ci.sh [build|test|both]
#   build - Only build the framework
#   test  - Only run tests
#   both  - Build framework and run tests (default)

set -e

# Default mode
MODE="${1:-both}"

# Project name (name of Xcode project file)
PROJECT_NAME="AriseMobileSdk"
# Scheme name (name of the scheme in Xcode, not the target name)
SCHEME_NAME="AriseMobileSdk"

# Framework output name (name of .xcframework and .framework files)
XCFRAMEWORK_NAME="AriseMobile"
FRAMEWORK_NAME="${XCFRAMEWORK_NAME}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}💡 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Set up paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_PATH="${PROJECT_ROOT}/src/${PROJECT_NAME}.xcodeproj"
OUTPUT_DIR="${SCRIPT_DIR}"
BUILD_DIR="${OUTPUT_DIR}/Build"

# DerivedData paths
# For build: use Build/DerivedData-Simulator
# For test (CI mode): use separate DerivedData-Tests directory that matches CI cache
BUILD_DERIVED_DATA_SIMULATOR="${OUTPUT_DIR}/Build/DerivedData-Simulator"

# In CI test mode, use a path that matches the workflow cache configuration
if [ "$MODE" = "test" ] && [ -n "$CI" ]; then
    # CI test job uses ios-sdk/DerivedData-Tests (relative to ios-sdk root)
    DERIVED_DATA="${DERIVED_DATA_OVERRIDE:-${PROJECT_ROOT}/DerivedData-Tests}"
else
    # Local or build mode: use the simulator build DerivedData
    DERIVED_DATA="${DERIVED_DATA_OVERRIDE:-$BUILD_DERIVED_DATA_SIMULATOR}"
fi

# Shared SourcePackages directory for all builds (speeds up dependency resolution)
SHARED_SOURCE_PACKAGES="${PROJECT_ROOT}/SourcePackages"
mkdir -p "${SHARED_SOURCE_PACKAGES}"

# Change to project root for relative paths
cd "$PROJECT_ROOT"

print_status "🚀 Starting CI script in mode: $MODE"
print_status "Project path: $PROJECT_PATH"
print_status "Output directory: $OUTPUT_DIR"

# ============================================================================
# RELINK FUNCTION - Remove SPM dependencies from framework binary
# ============================================================================

relink_framework_without_spm() {
    local DERIVED_DATA_PATH="$1"
    local SDK="$2"  # iphoneos or iphonesimulator
    local ARCH="$3" # arm64

    print_status "🔗 Relinking framework without SPM dependencies ($SDK)..."

    # Find the intermediates folder
    local INTERMEDIATES="${DERIVED_DATA_PATH}/Build/Intermediates.noindex/AriseMobileSdk.build/Release-${SDK}/${FRAMEWORK_NAME}.build"
    local OBJECTS_DIR="${INTERMEDIATES}/Objects-normal/${ARCH}"

    if [ ! -d "$OBJECTS_DIR" ]; then
        print_error "Objects directory not found: $OBJECTS_DIR"
        return 1
    fi

    # Find the framework binary location
    local FRAMEWORK_PATH="${DERIVED_DATA_PATH}/Build/Products/Release-${SDK}/${FRAMEWORK_NAME}.framework"
    local FRAMEWORK_BINARY="${FRAMEWORK_PATH}/${FRAMEWORK_NAME}"

    if [ ! -f "$FRAMEWORK_BINARY" ]; then
        print_error "Framework binary not found: $FRAMEWORK_BINARY"
        return 1
    fi

    # Backup original binary
    cp "$FRAMEWORK_BINARY" "${FRAMEWORK_BINARY}.original"

    # Find all .o files from our source code ONLY (not SPM dependencies)
    # We need to filter out SPM dependency .o files
    local FILTERED_LINK_FILE="${BUILD_DIR}/filtered_link_${SDK}.txt"

    # Find .o files ONLY in our framework's Objects directory (not in SourcePackages or other locations)
    # This excludes CryptoSwift.o, OpenAPIRuntime.o, HTTPTypes.o, etc.
    find "$OBJECTS_DIR" -maxdepth 1 -name "*.o" -type f > "$FILTERED_LINK_FILE"

    local OBJ_COUNT=$(wc -l < "$FILTERED_LINK_FILE" | xargs)
    print_status "Found $OBJ_COUNT object files (our code only, excluding SPM dependencies)"

    if [ "$OBJ_COUNT" -eq 0 ]; then
        print_error "No object files found in $OBJECTS_DIR"
        return 1
    fi

    # Show what we're linking
    print_status "Object files to link:"
    head -10 "$FILTERED_LINK_FILE"
    if [ "$OBJ_COUNT" -gt 10 ]; then
        print_status "... and $((OBJ_COUNT - 10)) more"
    fi

    # Get SDK path and CloudCommerce framework path
    local SDK_PATH
    local CLOUDCOMMERCE_FRAMEWORK_PATH
    if [ "$SDK" = "iphoneos" ]; then
        SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
        TARGET="arm64-apple-ios17.6"
        CLOUDCOMMERCE_FRAMEWORK_PATH="${OUTPUT_DIR}/CloudCommerce.xcframework/ios-arm64"
    else
        SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
        TARGET="arm64-apple-ios17.6-simulator"
        # Simulator might be ios-arm64_x86_64-simulator or ios-arm64-simulator
        if [ -d "${OUTPUT_DIR}/CloudCommerce.xcframework/ios-arm64_x86_64-simulator" ]; then
            CLOUDCOMMERCE_FRAMEWORK_PATH="${OUTPUT_DIR}/CloudCommerce.xcframework/ios-arm64_x86_64-simulator"
        else
            CLOUDCOMMERCE_FRAMEWORK_PATH="${OUTPUT_DIR}/CloudCommerce.xcframework/ios-arm64-simulator"
        fi
    fi

    print_status "CloudCommerce path: $CLOUDCOMMERCE_FRAMEWORK_PATH"

    # Relink using clang - create dynamic framework WITHOUT SPM static libraries
    print_status "Creating new framework binary without SPM dependencies..."

    # Use -undefined dynamic_lookup to allow undefined symbols
    # These will be resolved at runtime from the consuming app
    xcrun clang -target "$TARGET" \
        -dynamiclib \
        -isysroot "$SDK_PATH" \
        -F"${CLOUDCOMMERCE_FRAMEWORK_PATH}" \
        -framework CloudCommerce \
        -framework Foundation \
        -framework UIKit \
        -framework Security \
        -framework CryptoKit \
        -filelist "$FILTERED_LINK_FILE" \
        -install_name "@rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" \
        -Xlinker -rpath -Xlinker @executable_path/Frameworks \
        -Xlinker -rpath -Xlinker @loader_path/Frameworks \
        -Xlinker -undefined -Xlinker dynamic_lookup \
        -fobjc-link-runtime \
        -fprofile-instr-generate \
        -L"${SDK_PATH}/usr/lib/swift" \
        -L"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/${SDK}" \
        -o "$FRAMEWORK_BINARY" \
        2>&1 | tee "${BUILD_DIR}/relink_${SDK}.log"

    RELINK_EXIT_CODE=${PIPESTATUS[0]}

    if [ $RELINK_EXIT_CODE -ne 0 ]; then
        print_warning "Relink failed, restoring original binary"
        mv "${FRAMEWORK_BINARY}.original" "$FRAMEWORK_BINARY"
        cat "${BUILD_DIR}/relink_${SDK}.log"
        return 1
    fi

    # Clean up backup
    rm -f "${FRAMEWORK_BINARY}.original"

    print_success "Framework relinked successfully ($SDK)"

    # Show what's in the new binary
    print_status "Checking new binary symbols..."
    nm "$FRAMEWORK_BINARY" 2>/dev/null | grep -c "OpenAPIRuntime" || echo "OpenAPIRuntime symbols: 0"
    nm "$FRAMEWORK_BINARY" 2>/dev/null | grep -c "CryptoSwift" || echo "CryptoSwift symbols: 0"

    return 0
}

# ============================================================================
# BUILD SECTION
# ============================================================================

build_framework() {
    print_status "🔨 Building ${FRAMEWORK_NAME} framework..."

    DEVICE_DERIVED_DATA="${BUILD_DIR}/DerivedData-Device"
    SIMULATOR_DERIVED_DATA="${BUILD_DIR}/DerivedData-Simulator"

    # Clean output directory
    rm -rf ${OUTPUT_DIR}/${XCFRAMEWORK_NAME}.xcframework
    mkdir -p ${BUILD_DIR}
    
    # Check if CloudCommerce.xcframework exists
    CLOUDCOMMERCE_FRAMEWORK="${OUTPUT_DIR}/CloudCommerce.xcframework"
    if [ -d "$CLOUDCOMMERCE_FRAMEWORK" ]; then
        print_success "CloudCommerce.xcframework found at: $CLOUDCOMMERCE_FRAMEWORK"
    else
        print_warning "CloudCommerce.xcframework not found at: $CLOUDCOMMERCE_FRAMEWORK"
        print_warning "Creating minimal stub for CI build (this may cause Swift version compatibility issues)..."
        
        # Clean any existing CloudCommerce artifacts from DerivedData that might cause conflicts
        find "${DEVICE_DERIVED_DATA}" -name "*CloudCommerce*" -type d -exec rm -rf {} + 2>/dev/null || true
        find "${DEVICE_DERIVED_DATA}" -name "*CloudCommerce*" -type f -delete 2>/dev/null || true
        print_status "Cleaned existing CloudCommerce artifacts from DerivedData"
        mkdir -p "${CLOUDCOMMERCE_FRAMEWORK}/ios-arm64/CloudCommerce.framework"
        mkdir -p "${CLOUDCOMMERCE_FRAMEWORK}/ios-arm64/CloudCommerce.framework/Headers"
        mkdir -p "${CLOUDCOMMERCE_FRAMEWORK}/ios-arm64_x86_64-simulator/CloudCommerce.framework"
        mkdir -p "${CLOUDCOMMERCE_FRAMEWORK}/ios-arm64_x86_64-simulator/CloudCommerce.framework/Headers"
        
        # Create minimal Info.plist for XCFramework
        cat > "${CLOUDCOMMERCE_FRAMEWORK}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64</string>
            <key>LibraryPath</key>
            <string>CloudCommerce.framework</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
        </dict>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64_x86_64-simulator</string>
            <key>LibraryPath</key>
            <string>CloudCommerce.framework</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
                <string>x86_64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
            <key>SupportedPlatformVariant</key>
            <string>simulator</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF

        # Create minimal framework Info.plist for device
        cat > "${CLOUDCOMMERCE_FRAMEWORK}/ios-arm64/CloudCommerce.framework/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CloudCommerce</string>
    <key>CFBundleIdentifier</key>
    <string>com.arise.CloudCommerce</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>CloudCommerce</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
</dict>
</plist>
EOF

        # Create minimal framework Info.plist for simulator
        cp "${CLOUDCOMMERCE_FRAMEWORK}/ios-arm64/CloudCommerce.framework/Info.plist" "${CLOUDCOMMERCE_FRAMEWORK}/ios-arm64_x86_64-simulator/CloudCommerce.framework/Info.plist"
        
        print_status "Created CloudCommerce.xcframework stub"
    fi
    
    # Build for device
    print_status "📱 Building for device (arm64)..."

    # Reuse DerivedData to speed up builds
    print_status "Preparing DerivedData (reusing cached dependencies)..."
    mkdir -p "${DEVICE_DERIVED_DATA}"

    # Check if SourcePackages already cached
    if [ -d "${SHARED_SOURCE_PACKAGES}/checkouts" ]; then
        print_success "Using cached SourcePackages"
        RESOLVE_FLAG="-disableAutomaticPackageResolution"
    else
        print_status "Will resolve dependencies during build"
        RESOLVE_FLAG=""
    fi

    # Build for device
    print_status "Building scheme: ${SCHEME_NAME} for device..."
    xcodebuild \
        -project "${PROJECT_PATH}" \
        -scheme "${SCHEME_NAME}" \
        -configuration Release \
        -sdk iphoneos \
        -arch arm64 \
        -derivedDataPath "${DEVICE_DERIVED_DATA}" \
        -clonedSourcePackagesDirPath "${SHARED_SOURCE_PACKAGES}" \
        $RESOLVE_FLAG \
        -skipPackagePluginValidation \
        -skipMacroValidation \
        build \
        2>&1 | tee "${BUILD_DIR}/device_build.log"

    BUILD_EXIT_CODE=${PIPESTATUS[0]}

    if [ $BUILD_EXIT_CODE -ne 0 ]; then
        print_error "Device build failed with exit code: $BUILD_EXIT_CODE"
        tail -100 "${BUILD_DIR}/device_build.log" || true
        exit 1
    fi

    # Relink framework without SPM dependencies (double-build trick)
    if relink_framework_without_spm "$DEVICE_DERIVED_DATA" "iphoneos" "arm64"; then
        print_success "Device framework relinked without SPM dependencies"
    else
        print_warning "Relink failed, using original framework (may have duplicate symbols)"
    fi

    # Search for framework in DerivedData
    print_status "Searching for framework in DerivedData..."
    DEVICE_FRAMEWORK="${DEVICE_DERIVED_DATA}/Build/Products/Release-iphoneos/${FRAMEWORK_NAME}.framework"
    if [ ! -d "$DEVICE_FRAMEWORK" ]; then
        DEVICE_FRAMEWORK=$(find "${DEVICE_DERIVED_DATA}" -name "${FRAMEWORK_NAME}.framework" -type d 2>/dev/null | head -1)
    fi
    
    if [ -z "$DEVICE_FRAMEWORK" ] || [ ! -d "$DEVICE_FRAMEWORK" ]; then
        print_error "Device framework not found"
        exit 1
    fi
    
    print_success "Device framework found: $DEVICE_FRAMEWORK"
    
    # Build for simulator
    print_status "📱 Building for simulator (arm64)..."

    # Reuse DerivedData to speed up builds
    print_status "Preparing DerivedData (reusing cached dependencies)..."
    mkdir -p "${SIMULATOR_DERIVED_DATA}"

    # Build for simulator (SourcePackages already resolved from device build)
    print_status "Building scheme: ${SCHEME_NAME} for simulator..."
    xcodebuild \
        -project "${PROJECT_PATH}" \
        -scheme "${SCHEME_NAME}" \
        -configuration Release \
        -destination "generic/platform=iOS Simulator" \
        -sdk iphonesimulator \
        -derivedDataPath "${SIMULATOR_DERIVED_DATA}" \
        -clonedSourcePackagesDirPath "${SHARED_SOURCE_PACKAGES}" \
        -disableAutomaticPackageResolution \
        -skipPackagePluginValidation \
        -skipMacroValidation \
        build \
        2>&1 | tee "${BUILD_DIR}/simulator_build.log"

    BUILD_EXIT_CODE=${PIPESTATUS[0]}
    if [ $BUILD_EXIT_CODE -ne 0 ]; then
        print_error "Simulator build failed with exit code: $BUILD_EXIT_CODE"
        tail -50 "${BUILD_DIR}/simulator_build.log" || true
        exit 1
    fi

    # Relink framework without SPM dependencies (double-build trick)
    if relink_framework_without_spm "$SIMULATOR_DERIVED_DATA" "iphonesimulator" "arm64"; then
        print_success "Simulator framework relinked without SPM dependencies"
    else
        print_warning "Relink failed, using original framework (may have duplicate symbols)"
    fi

    # Search for framework in DerivedData
    print_status "Searching for framework in DerivedData..."
    SIMULATOR_FRAMEWORK="${SIMULATOR_DERIVED_DATA}/Build/Products/Release-iphonesimulator/${FRAMEWORK_NAME}.framework"
    if [ ! -d "$SIMULATOR_FRAMEWORK" ]; then
        SIMULATOR_FRAMEWORK=$(find "${SIMULATOR_DERIVED_DATA}" -name "${FRAMEWORK_NAME}.framework" -type d 2>/dev/null | head -1)
    fi
    
    if [ -z "$SIMULATOR_FRAMEWORK" ] || [ ! -d "$SIMULATOR_FRAMEWORK" ]; then
        print_error "Simulator framework not found"
        exit 1
    fi
    
    print_success "Simulator framework found: $SIMULATOR_FRAMEWORK"
    
    # Create XCFramework
    print_status "📦 Creating XCFramework..."
    
    xcframework_path="${OUTPUT_DIR}/${XCFRAMEWORK_NAME}.xcframework"
    rm -rf "${xcframework_path}"
    
    print_status "Creating XCFramework from:"
    print_status "  Device: $DEVICE_FRAMEWORK"
    print_status "  Simulator: $SIMULATOR_FRAMEWORK"
    print_status "  Output: $xcframework_path"
    
    xcodebuild -create-xcframework \
        -framework "${DEVICE_FRAMEWORK}" \
        -framework "${SIMULATOR_FRAMEWORK}" \
        -output "${xcframework_path}" 2>&1 | tee "${BUILD_DIR}/xcframework_create.log"
    
    XCFRAMEWORK_EXIT_CODE=${PIPESTATUS[0]}
    
    if [ $XCFRAMEWORK_EXIT_CODE -ne 0 ]; then
        print_error "Failed to create XCFramework (exit code: $XCFRAMEWORK_EXIT_CODE)"
        cat "${BUILD_DIR}/xcframework_create.log" || true
        exit 1
    fi
    
    if [ ! -d "${xcframework_path}" ]; then
        print_error "XCFramework directory not found after creation"
        exit 1
    fi
    
    print_success "XCFramework created: ${xcframework_path}"
    print_success "🎉 Build completed successfully!"
}

# ============================================================================
# TEST SECTION
# ============================================================================

run_tests() {
    print_status "🧪 Running tests..."
    echo ""

    # Show DerivedData path being used
    print_status "DerivedData path: $DERIVED_DATA"

    # Check if DerivedData has cached build products
    if [ -d "$DERIVED_DATA/Build/Products" ]; then
        echo "📦 Found existing DerivedData - reusing cached build products"
        ls -la "$DERIVED_DATA/Build/Products/" 2>/dev/null | head -5 || true
    else
        echo "📦 No cached DerivedData found, will compile during test"
        mkdir -p "$DERIVED_DATA"
        if [ -n "$CI" ]; then
            echo "   (This is expected on first CI run - cache will speed up subsequent runs)"
        fi
    fi

    # Clean old test results
    rm -rf "$PROJECT_ROOT/test-results.xcresult" 2>/dev/null || true
    
    # Find available simulator using xcodebuild to get compatible destinations
    echo "📱 Finding compatible simulator..."
    echo "Getting compatible destinations from xcodebuild..."
    
    # First, show all available destinations for debugging
    echo "Available destinations:"
    xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME_NAME" -showdestinations 2>&1 | grep -E "(platform:|name:)" || true
    echo ""
    
    # Get destinations that xcodebuild can actually use, filter for iPhone iOS Simulator only (not Mac Catalyst)
    # Don't use -destination flag with -showdestinations, it filters results incorrectly
    # Use 2>&1 to capture both stdout and stderr, then filter
    echo "🔍 Searching for iPhone simulators in destinations..."
    DESTINATIONS=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME_NAME" -showdestinations 2>&1 | grep "platform:iOS Simulator" | grep "name:iPhone" || true)
    
    if [ -n "$DESTINATIONS" ]; then
        DESTINATION_COUNT=$(echo "$DESTINATIONS" | wc -l | xargs)
        echo "✅ Found $DESTINATION_COUNT iPhone simulator destination(s)"
    else
        echo "⚠️  No iPhone simulators found in xcodebuild destinations"
    fi
    
    if [ -z "$DESTINATIONS" ]; then
        echo "⚠️  No specific iPhone simulator found in destinations"
        echo "Attempting to list available simulators using xcrun simctl..."
        
        # First, check for booted simulators (these are most likely to work)
        BOOTED_SIMULATORS=$(xcrun simctl list devices 2>/dev/null | grep "iPhone" | grep "Booted" || true)
        
        if [ -n "$BOOTED_SIMULATORS" ]; then
            echo "✅ Found booted iPhone simulators:"
            echo "$BOOTED_SIMULATORS"
            echo ""
            # Extract first booted simulator ID
            BOOTED_SIMULATOR_ID=$(echo "$BOOTED_SIMULATORS" | head -1 | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' | head -1)
            if [ -n "$BOOTED_SIMULATOR_ID" ]; then
                echo "📱 Using booted simulator: $BOOTED_SIMULATOR_ID"
                DESTINATION="platform=iOS Simulator,id=$BOOTED_SIMULATOR_ID"
            else
                echo "⚠️  Could not extract booted simulator ID, trying available simulators..."
                AVAILABLE_SIMULATORS=$(xcrun simctl list devices available 2>/dev/null | grep "iPhone" || true)
                if [ -n "$AVAILABLE_SIMULATORS" ]; then
                    echo "Available iPhone simulators:"
                    echo "$AVAILABLE_SIMULATORS"
                    echo ""
                    echo "Using generic iOS Simulator destination - xcodebuild will select one automatically"
                    DESTINATION="platform=iOS Simulator,name=iPhone"
                else
                    echo "Trying generic destination as fallback..."
                    DESTINATION="platform=iOS Simulator,name=iPhone"
                fi
            fi
        else
            # Try to list available simulators
            AVAILABLE_SIMULATORS=$(xcrun simctl list devices available 2>/dev/null | grep "iPhone" || true)
            
            if [ -n "$AVAILABLE_SIMULATORS" ]; then
                echo "Available iPhone simulators:"
                echo "$AVAILABLE_SIMULATORS"
                echo ""
                echo "⚠️  Simulators exist but not showing in xcodebuild destinations"
                echo "Using generic iOS Simulator destination - xcodebuild will select one automatically"
                DESTINATION="platform=iOS Simulator,name=iPhone"
            else
                echo "❌ No iPhone simulators found at all"
                echo "This might be a CI environment issue - simulators may need to be booted first"
                echo "Trying generic destination as fallback..."
                DESTINATION="platform=iOS Simulator,name=iPhone"
            fi
        fi
    else
        echo "✅ Found iPhone simulators in destinations"
        echo "Destinations (showing first 5):"
        echo "$DESTINATIONS" | head -5
        echo ""
        
        # Extract first iPhone simulator ID (prefer newer OS versions)
        # Format: { platform:iOS Simulator, arch:arm64, id:XXXXX, OS:XX.X, name:iPhone XX }
        # Try to extract ID directly using regex
        SIMULATOR_UDID=$(echo "$DESTINATIONS" | grep -oE 'id:[A-F0-9-]+' | head -1 | cut -d: -f2 || true)
        
        # If that didn't work, try a different approach - get the first line and extract from it
        if [ -z "$SIMULATOR_UDID" ]; then
            FIRST_LINE=$(echo "$DESTINATIONS" | head -1 || true)
            if [ -n "$FIRST_LINE" ]; then
                SIMULATOR_UDID=$(echo "$FIRST_LINE" | grep -oE 'id:[A-F0-9-]+' | cut -d: -f2 | head -1 || true)
            fi
        fi
        
        # Extract name and OS for logging
        if [ -n "$SIMULATOR_UDID" ]; then
            SIMULATOR_LINE=$(echo "$DESTINATIONS" | grep "$SIMULATOR_UDID" | head -1 || true)
            if [ -n "$SIMULATOR_LINE" ]; then
                SIMULATOR_NAME=$(echo "$SIMULATOR_LINE" | grep -oE 'name:[^,}]+' | cut -d: -f2 | xargs || echo "Unknown")
                SIMULATOR_OS=$(echo "$SIMULATOR_LINE" | grep -oE 'OS:[0-9.]+' | cut -d: -f2 || echo "Unknown")
            else
                SIMULATOR_NAME="Unknown"
                SIMULATOR_OS="Unknown"
            fi
        fi
        
        if [ -z "$SIMULATOR_UDID" ]; then
            echo "⚠️  Could not extract simulator ID from destinations"
            echo "Destinations found:"
            echo "$DESTINATIONS" | head -3
            echo ""
            echo "Using generic destination as fallback..."
            DESTINATION="platform=iOS Simulator,name=iPhone"
        else
            echo "📱 Selected simulator: $SIMULATOR_NAME (OS: $SIMULATOR_OS, ID: $SIMULATOR_UDID)"
            
            # Check if simulator is booted, if not, boot it
            set +e  # Temporarily disable exit on error for simulator state check
            SIMULATOR_STATE=$(xcrun simctl list devices 2>/dev/null | grep "$SIMULATOR_UDID" | grep -oE "(Booted|Shutdown)" || echo "Unknown")
            set -e  # Re-enable exit on error
            
            if [ "$SIMULATOR_STATE" != "Booted" ]; then
                echo "🚀 Booting simulator $SIMULATOR_UDID..."
                set +e  # Temporarily disable exit on error for boot command
                xcrun simctl boot "$SIMULATOR_UDID" 2>&1
                BOOT_EXIT_CODE=$?
                set -e  # Re-enable exit on error
                
                if [ $BOOT_EXIT_CODE -ne 0 ]; then
                    # If boot fails, check if it's already booted (race condition)
                    sleep 2
                    set +e
                    SIMULATOR_STATE=$(xcrun simctl list devices 2>/dev/null | grep "$SIMULATOR_UDID" | grep -oE "(Booted|Shutdown)" || echo "Unknown")
                    set -e
                    if [ "$SIMULATOR_STATE" != "Booted" ]; then
                        echo "⚠️  Failed to boot simulator, but continuing - xcodebuild may boot it automatically"
                    else
                        echo "✅ Simulator is now booted"
                    fi
                else
                    echo "✅ Simulator booted successfully"
                fi
            else
                echo "✅ Simulator is already booted"
            fi
            
            DESTINATION="platform=iOS Simulator,id=$SIMULATOR_UDID"
        fi
    fi
    
    # Ensure DESTINATION is set (safety check)
    if [ -z "$DESTINATION" ]; then
        echo "❌ Error: DESTINATION is not set!"
        echo "Falling back to generic iOS Simulator destination..."
        DESTINATION="platform=iOS Simulator,name=iPhone"
    fi
    
    # Show final destination being used
    echo "📍 Final destination: $DESTINATION"
    echo ""

    # Run tests (dependencies resolved automatically during build)
    echo "🧪 Running tests..."

    # Check if SourcePackages already cached
    if [ -d "${SHARED_SOURCE_PACKAGES}/checkouts" ]; then
        echo "✅ Using cached SourcePackages"
        RESOLVE_FLAG="-disableAutomaticPackageResolution"
    else
        echo "📦 Will resolve dependencies during build"
        RESOLVE_FLAG=""
    fi
    echo ""

    # Run xcodebuild test
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug \
        -destination "$DESTINATION" \
        -derivedDataPath "$DERIVED_DATA" \
        -clonedSourcePackagesDirPath "${SHARED_SOURCE_PACKAGES}" \
        $RESOLVE_FLAG \
        -skipPackagePluginValidation \
        -skipMacroValidation \
        -resultBundlePath "$PROJECT_ROOT/test-results.xcresult" \
        -parallel-testing-enabled NO \
        2>&1 | tee /tmp/test_output.log
    
    TEST_EXIT_CODE=${PIPESTATUS[0]}
    
    echo ""
    if [ $TEST_EXIT_CODE -eq 0 ]; then
        echo "✅ All tests passed!"
        echo ""
        echo "📊 Test summary:"
        # Try to extract test summary from output
        grep -E "(Test Suite|Test Case|passed|failed)" /tmp/test_output.log | tail -20 || true
    else
        echo "❌ Tests failed with exit code: $TEST_EXIT_CODE"
        echo ""
        echo "Last 100 lines of test output:"
        tail -100 /tmp/test_output.log || true
        echo ""
        echo "Build timing summary:"
        grep -A 20 "Build Timing Summary" /tmp/test_output.log || true
        exit $TEST_EXIT_CODE
    fi
    
    echo ""
    echo "✅ Tests completed successfully!"
    echo "Results saved to: $PROJECT_ROOT/test-results.xcresult"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

case "$MODE" in
    build)
        build_framework
        ;;
    test)
        run_tests
        ;;
    both)
        build_framework
        run_tests
        ;;
    *)
        print_error "Invalid mode: $MODE"
        print_status "Usage: $0 [build|test|both]"
        exit 1
        ;;
esac

print_success "🎉 CI script completed successfully in mode: $MODE"

