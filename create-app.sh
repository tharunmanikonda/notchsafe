#!/bin/bash

set -e

APP_NAME="NotchSafe"
BUNDLE_ID="com.tharun.notchsafe"
BUILD_DIR=".build/release"
APP_DIR="$APP_NAME.app"

echo "📦 Creating $APP_NAME.app bundle..."

# Clean previous build
rm -rf "$APP_DIR"

# Create app structure
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/NotchSafe" "$APP_DIR/Contents/MacOS/"

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>NotchSafe</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "$APP_DIR/Contents/PkgInfo"

echo "✅ App bundle created: $APP_DIR"
echo ""
echo "🚀 To run:"
echo "   open $APP_DIR"
echo ""
echo "📂 To move to Applications:"
echo "   mv $APP_DIR /Applications/"
