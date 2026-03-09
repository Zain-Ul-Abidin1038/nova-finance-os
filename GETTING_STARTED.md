# Getting Started with Nova Live Finance OS

Welcome to **Nova Live Finance OS** - your AI-powered financial life operating system with grounded intelligence!

## 🚀 Quick Start

### Prerequisites

1. **Flutter SDK** (^3.10.8)
   ```bash
   flutter --version
   ```

2. **Google Cloud Account**
   - Create project at [Google Cloud Console](https://console.cloud.google.com)
   - Enable Nova API
   - Generate API key

3. **AWS Account** (Optional for cloud features)
   - Install Amplify CLI: `npm install -g @aws-amplify/cli`
   - Configure credentials

4. **Firebase Account** (Optional for real-time features)
   - Create project at [Firebase Console](https://console.firebase.google.com)

### Installation Steps

#### 1. Clone or Download
```bash
# If you have the project locally, navigate to it
cd nova_live_nova_finance_os
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Configure Environment
```bash
# Copy example env file
cp .env.example .env

# Edit .env with your API keys
nano .env  # or use your preferred editor
```

Add your Nova API key:
```
GEMINI_API_KEY=your_nova_api_key_here
```

#### 4. Run the App
```bash
# Run on connected device
flutter run

# Or run on specific platform
flutter run -d chrome        # Web
flutter run -d emulator-5554 # Android
flutter run -d iPhone        # iOS
```

## 🎯 Key Features to Try

### 1. Grounded Search Chat
- Navigate to "Grounded Chat" from home screen
- Ask factual questions like:
  - "What is the current corporate tax rate?"
  - "What expenses are 50% deductible?"
- Watch live status updates and see citations!

### 2. Vision Nova
- Navigate to "Vision Nova" from home screen
- Point camera at receipts
- Get real-time AI advice while scanning
- Capture for detailed analysis

### 3. NovaNavigator
- Navigate to "NovaNavigator" from home screen
- Tell the AI what task to perform
- Watch it plan and execute autonomously

### 4. Smart Receipt Scanning
- Go to "Receipt Scanner"
- Capture receipt with camera
- AI automatically:
  - Extracts vendor, amount, date
  - Calculates tax deductions
  - Categorizes expense

### 5. Intelligent Chat
- Open "Chat" from home screen
- Natural language commands:
  - "Add 500 rupees given to bilal"
  - "How much did I spend on dining?"
  - "Show my financial health"

## 📱 Platform-Specific Setup

### Android
```bash
# Build APK
flutter build apk

# Install on device
flutter install
```

### iOS
```bash
# Build iOS app
flutter build ios

# Open in Xcode for signing
open ios/Runner.xcworkspace
```

### Web
```bash
# Build web app
flutter build web

# Serve locally
flutter run -d chrome
```

## 🔧 Configuration

### Firebase (Optional)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

### AWS Amplify (Optional)
```bash
# Initialize Amplify
amplify init

# Add authentication
amplify add auth

# Add storage
amplify add storage

# Push to cloud
amplify push
```

### Vertex AI Search (Optional for Document Grounding)
1. Create a datastore in Google Cloud Console
2. Add documents to the datastore
3. Update `.env`:
   ```
   GCP_PROJECT_ID=your_project_id
   VERTEX_DATASTORE_ID=your_datastore_id
   ```

## 📚 Documentation

- **README.md** - Complete project overview
- **GROUNDED_SEARCH_FEATURE.md** - Grounded search documentation
- **VISION_GHOST_FEATURE.md** - Vision Nova feature guide
- **GHOST_NAVIGATOR_FEATURE.md** - NovaNavigator guide

## 🐛 Troubleshooting

### Common Issues

**1. "Nova API key not found"**
- Ensure `.env` file exists in project root
- Check that `GEMINI_API_KEY` is set correctly
- Restart the app after adding the key

**2. "Camera permission denied"**
- Grant camera permission in device settings
- Restart the app

**3. "Build failed"**
- Run `flutter clean`
- Run `flutter pub get`
- Try again

**4. "Grounded search not working"**
- Verify Nova API key is valid
- Check internet connection
- Ensure you're using Nova 1.5 or later

## 💡 Tips

1. **Start Simple**: Try the chat interface first to get familiar with AI capabilities
2. **Use Grounded Search**: For factual questions, use the Grounded Chat screen
3. **Scan Receipts**: The Vision Nova feature provides real-time feedback
4. **Explore Features**: Check out all screens from the home dashboard

## 🤝 Need Help?

- Check the documentation in the `/docs` folder
- Review example code in `/lib/features`
- Open an issue on GitHub (if applicable)

## 🎉 You're Ready!

Start exploring Nova Live Finance OS and experience the future of AI-powered financial management!

---

**Version:** 4.1.0 (Grounded Intelligence Edition)  
**Last Updated:** March 5, 2026
