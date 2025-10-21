# 🔐 Secure Setup Guide

## 🚨 **IMPORTANT: API Keys Security**

Your API keys are now **SECURE** and not visible in the repository!

## 🚀 **Quick Setup**

### 1. **First Time Setup**
```bash
# Run the setup script
./setup_keys.sh

# Edit the .env file with your actual keys
nano .env
```

### 2. **Add Your API Keys**
Edit the `.env` file and replace the placeholder values:
```bash
TAXON_SUBSCRIPTION_KEY=your_actual_taxon_key_here
SPECIES_SUBSCRIPTION_KEY=your_actual_species_key_here
```

### 3. **Run the App**
```bash
# iOS
./run_ios.sh

# Web/Chrome
flutter run --dart-define=TAXON_SUBSCRIPTION_KEY=your_key --dart-define=SPECIES_SUBSCRIPTION_KEY=your_key -d chrome
```

## 🔒 **Security Features**

✅ **`.env` file is in `.gitignore`** - Never committed to repository  
✅ **No hardcoded keys** in scripts  
✅ **Template file** (`env.example`) for easy setup  
✅ **Automatic key loading** from environment variables  

## 👥 **Team Collaboration**

When team members clone the repository:

1. **They get the template**: `env.example`
2. **They run setup**: `./setup_keys.sh` 
3. **They add their keys**: Edit `.env` file
4. **They run the app**: `./run_ios.sh`

**No API keys are ever shared or committed!** 🎉

## 🛠️ **Manual Setup (Alternative)**

If you prefer to set keys manually:

```bash
# Set environment variables
export TAXON_SUBSCRIPTION_KEY=your_key
export SPECIES_SUBSCRIPTION_KEY=your_key

# Run the app
./run_ios.sh
```

## 📁 **File Structure**

```
├── .env                    # 🔒 Your API keys (NOT in git)
├── env.example            # 📋 Template for team members
├── setup_keys.sh          # 🛠️  Setup script
├── run_ios.sh             # 🚀 Run script (loads from .env)
└── .gitignore             # 🛡️  Protects .env files
```

Your API keys are now **100% secure**! 🔐✨
