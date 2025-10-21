#!/bin/bash

# Run Flutter app on iOS with API keys
# Load API keys from .env file if it exists
if [ -f .env ]; then
    echo "📁 Loading API keys from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  No .env file found. Please run ./setup_keys.sh first"
    echo "   Or set environment variables manually:"
    echo "   TAXON_SUBSCRIPTION_KEY=your_key SPECIES_SUBSCRIPTION_KEY=your_key ./run_ios.sh"
    exit 1
fi

# Check if keys are set
if [ -z "$TAXON_SUBSCRIPTION_KEY" ] || [ -z "$SPECIES_SUBSCRIPTION_KEY" ]; then
    echo "❌ API keys not found in .env file"
    echo "   Please edit .env file and add your keys"
    exit 1
fi

echo "🚀 Starting Flutter app on iPhone 16..."
flutter run \
  --dart-define=TAXON_SUBSCRIPTION_KEY=${TAXON_SUBSCRIPTION_KEY} \
  --dart-define=SPECIES_SUBSCRIPTION_KEY=${SPECIES_SUBSCRIPTION_KEY} \
  -d "iPhone 16"