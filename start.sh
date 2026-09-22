#!/bin/bash
# Dev Context Switcher Launch Script

echo "🚀 Starting Dev Context Switcher..."

# Check if we're in the project directory
if [ ! -f "pubspec.yaml" ]; then
  echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
  exit 1
fi

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run the app
echo "🏃 Running the app..."
flutter run "$@"

echo "✅ Done!"