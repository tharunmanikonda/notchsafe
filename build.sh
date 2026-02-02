#!/bin/bash

set -e

echo "🏗️ Building NotchSafe..."

# Build release
swift build -c release

echo "✅ Build complete!"
echo ""
echo "📦 Binary location:"
echo "   .build/release/NotchSafe"
echo ""
echo "🚀 To run:"
echo "   .build/release/NotchSafe"
echo ""
echo "📁 To create app bundle:"
echo "   ./create-app.sh"
