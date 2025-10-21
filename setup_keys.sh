#!/bin/bash

# Setup script for API keys
echo "🔐 Setting up API keys for WildGuess..."

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists. Do you want to overwrite it? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled."
        exit 1
    fi
fi

# Copy example file
cp env.example .env

echo "✅ Created .env file from template"
echo ""
echo "🔧 Please edit .env file and add your actual API keys:"
echo "   - TAXON_SUBSCRIPTION_KEY=your_actual_taxon_key"
echo "   - SPECIES_SUBSCRIPTION_KEY=your_actual_species_key"
echo ""
echo "📝 You can edit it with: nano .env"
echo "🚀 Then run: ./run_ios.sh"
