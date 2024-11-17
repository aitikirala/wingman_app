#!/bin/bash

# Run flutter pub get
echo "Running flutter pub get..."
flutter pub get

# Navigate to the ios folder
cd ios || exit

# Install CocoaPods dependencies
echo "Running pod install..."
pod install

# Ensure CocoaPods is up to date
echo "Ensuring CocoaPods is installed..."
sudo gem install cocoapods

# Navigate back to the project root
cd ..

echo "Setup complete!"
