# Finance OS - Installation Guide

**Version:** 1.0.0  
**Last Updated:** February 10, 2026

---

## 📱 Android Installation

### Method 1: Direct APK Installation (Recommended)

#### Step 1: Download APK
1. Go to [GitHub Releases](https://github.com/your-org/nova_finance_os/releases)
2. Download `nova-accountant-v1.0.0-android.apk` (73.7 MB)
3. Save to your device

#### Step 2: Enable Unknown Sources
1. Open **Settings** on your Android device
2. Navigate to **Security** or **Privacy**
3. Find **Install Unknown Apps** or **Unknown Sources**
4. Select your browser or file manager
5. Toggle **Allow from this source** to ON

**Note:** Steps may vary by Android version and manufacturer.

#### Step 3: Install APK
1. Open your **File Manager** or **Downloads** app
2. Locate `nova-accountant-v1.0.0-android.apk`
3. Tap the APK file
4. Tap **Install**
5. Wait for installation to complete (10-30 seconds)
6. Tap **Open** to launch the app

#### Step 4: Grant Permissions
On first launch, the app will request permissions:

1. **Camera** - Required for receipt scanning
   - Tap **Allow** when prompted
   
2. **Storage** - Required for saving images
   - Tap **Allow** when prompted
   
3. **Location** - Optional for expense context
   - Tap **Allow** or **Deny** based on preference
   
4. **Microphone** - Optional for voice input
   - Tap **Allow** or **Deny** based on preference
   
5. **Calendar** - Optional for event integration
   - Tap **Allow** or **Deny** based on preference

---

### Method 2: ADB Installation (For Developers)

#### Prerequisites
- Android Debug Bridge (ADB) installed
- USB debugging enabled on device
- Device connected via USB

#### Steps
```bash
# Navigate to download folder
cd ~/Downloads

# Install APK via ADB
adb install nova-accountant-v1.0.0-android.apk

# Launch app
adb shell am start -n com.example.novaAccountant/.MainActivity
```

---

## 🍎 iOS Installation (Coming Soon)

### TestFlight Beta (Coming Soon)

#### Step 1: Install TestFlight
1. Open **App Store** on your iPhone/iPad
2. Search for **TestFlight**
3. Download and install TestFlight (free)

#### Step 2: Join Beta
1. Open beta invitation link (will be provided)
2. Tap **View in TestFlight**
3. Tap **Accept** to join beta
4. Tap **Install** to download app

#### Step 3: Launch App
1. Open TestFlight app
2. Find **Finance OS** in your apps
3. Tap **Open**
4. Grant permissions when prompted

### App Store (Coming Q2 2026)
- Full App Store release planned for Q2 2026
- Will support iOS 12.0 and later
- No TestFlight required

---

## ⚙️ Initial Configuration

### Step 1: Create Account

1. Launch Finance OS
2. Tap **Sign Up**
3. Enter your email address
4. Create a strong password (min 8 characters)
5. Tap **Create Account**
6. Verify your email (check inbox)

### Step 2: Configure Nova API

**Important:** Finance OS requires a Nova API key for AI features.

#### Get Nova API Key (Free)
1. Visit [AWS Console](https://console.aws.amazon.com/bedrock/)
2. Sign in with your AWS account
3. Enable Amazon Nova models in Bedrock
4. Create IAM user with Bedrock permissions
5. Copy the Access Key ID and Secret Access Key

#### Add API Key to App
1. Open Finance OS
2. Tap **Settings** (gear icon)
3. Tap **API Configuration**
4. Paste your AWS credentials
5. Tap **Save**
6. Restart the app

**Cost:** Amazon Nova via Bedrock is pay-per-use (~$0.78/month for typical use)

### Step 3: Configure AWS (Optional)

**Note:** AWS configuration is optional. The app works without it, but some features require AWS.

#### Required for:
- Cross-device sync
- Cloud backup
- Audit trail storage
- Multi-user features

#### Setup Steps:
1. Create AWS account at [aws.amazon.com](https://aws.amazon.com)
2. Follow [AWS_SETUP_GUIDE.md](AWS_SETUP_GUIDE.md) for detailed instructions
3. Configure credentials in app settings

### Step 4: Test Receipt Scanning

1. Tap **Camera** icon on home screen
2. Take a photo of any receipt
3. Wait for AI analysis (5-10 seconds)
4. Review extracted data
5. Tap **Save** to confirm

**Tips for best results:**
- Use good lighting
- Keep receipt flat and straight
- Ensure text is readable
- Avoid shadows and glare

---

## 🔧 Troubleshooting

### Installation Issues

#### "App not installed" Error
**Cause:** Insufficient storage or corrupted APK

**Solution:**
1. Free up at least 200 MB storage
2. Re-download APK file
3. Try installation again

#### "Parse Error" Message
**Cause:** Incompatible Android version or corrupted file

**Solution:**
1. Check Android version (requires 5.0+)
2. Re-download APK from official source
3. Verify file size (should be ~73.7 MB)

#### "Installation Blocked" Warning
**Cause:** Unknown sources not enabled

**Solution:**
1. Go to Settings > Security
2. Enable "Unknown Sources" or "Install Unknown Apps"
3. Try installation again

### Permission Issues

#### Camera Not Working
**Solution:**
1. Go to Settings > Apps > Finance OS
2. Tap Permissions
3. Enable Camera permission
4. Restart app

#### Storage Access Denied
**Solution:**
1. Go to Settings > Apps > Finance OS
2. Tap Permissions
3. Enable Storage permission
4. Restart app

### API Configuration Issues

#### "Invalid API Key" Error
**Solution:**
1. Verify AWS credentials are copied correctly (no spaces)
2. Check IAM user has Bedrock permissions in AWS Console
3. Ensure Amazon Nova models are enabled in Bedrock
4. Try generating new access keys

#### "API Quota Exceeded" Error
**Solution:**
1. Check usage in AWS Bedrock Console
2. Wait for quota reset (usually 24 hours)
3. Request a service limit increase
4. Reduce API usage temporarily

### Performance Issues

#### App Slow to Start
**Cause:** First launch initialization

**Solution:**
- Wait 5-10 seconds on first launch
- Subsequent launches will be faster
- Clear cache if problem persists

#### Receipt Analysis Slow
**Cause:** Network latency or large image

**Solution:**
1. Check internet connection
2. Use smaller image size
3. Ensure good lighting (reduces processing)
4. Try again during off-peak hours

#### App Crashes
**Solution:**
1. Clear app cache: Settings > Apps > Finance OS > Clear Cache
2. Restart device
3. Reinstall app
4. Report issue on GitHub

---

## 🔄 Updating the App

### Android Update

#### Method 1: Manual Update
1. Download new APK from GitHub Releases
2. Install over existing app (data preserved)
3. Launch updated app

#### Method 2: In-App Update (Coming Soon)
- Automatic update notifications
- One-tap update process
- No data loss

### iOS Update

#### TestFlight
- Updates automatically via TestFlight
- Notification when new version available

#### App Store
- Updates via App Store (standard process)

---

## 🗑️ Uninstallation

### Android

#### Method 1: Via Settings
1. Go to Settings > Apps
2. Find Finance OS
3. Tap Uninstall
4. Confirm removal

#### Method 2: Via Home Screen
1. Long-press app icon
2. Drag to Uninstall
3. Confirm removal

**Note:** All local data will be deleted. Cloud data (if AWS configured) remains.

### iOS

1. Long-press app icon
2. Tap Remove App
3. Tap Delete App
4. Confirm deletion

---

## 💾 Data Backup

### Local Backup (Automatic)
- Data stored in encrypted Hive database
- Automatic backup on device
- Survives app updates

### Cloud Backup (Optional - Requires AWS)
- Automatic sync to AWS S3
- Cross-device synchronization
- 90-day retention

### Manual Export
1. Open Settings
2. Tap Data Management
3. Tap Export Data
4. Choose format (JSON/CSV)
5. Save to device or cloud

---

## 🔐 Security Best Practices

### API Key Security
- ✅ Never share your AWS credentials
- ✅ Rotate keys regularly (every 90 days)
- ✅ Use separate keys for dev/prod
- ✅ Monitor usage in AWS Bedrock Console

### Account Security
- ✅ Use strong, unique password
- ✅ Enable two-factor authentication (when available)
- ✅ Don't share account credentials
- ✅ Log out on shared devices

### Device Security
- ✅ Enable device lock screen
- ✅ Use biometric authentication
- ✅ Keep Android/iOS updated
- ✅ Install from official sources only

---

## 📞 Getting Help

### Support Channels

#### Documentation
- **README.md** - Complete overview
- **QUICK_START_GUIDE.md** - Quick start
- **FAQ.md** - Frequently asked questions (coming soon)

#### Community
- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Community support
- **Discord** - Real-time chat (coming soon)

#### Direct Support
- **Email:** support@novaaccountant.com
- **Response Time:** 24-48 hours
- **Priority Support:** Available for enterprise users

### Reporting Issues

When reporting issues, please include:
1. Device model and Android/iOS version
2. App version (Settings > About)
3. Steps to reproduce the issue
4. Screenshots (if applicable)
5. Error messages (if any)

---

## ✅ Installation Checklist

### Pre-Installation
- [ ] Android 5.0+ or iOS 12.0+
- [ ] 200 MB free storage
- [ ] Internet connection
- [ ] AWS account (for AI features)

### Installation
- [ ] Downloaded APK/TestFlight
- [ ] Enabled unknown sources (Android)
- [ ] Installed app successfully
- [ ] Granted required permissions

### Configuration
- [ ] Created account
- [ ] Verified email
- [ ] Added AWS credentials
- [ ] Tested receipt scanning
- [ ] Configured AWS (optional)

### Verification
- [ ] App launches successfully
- [ ] Receipt scanning works
- [ ] Chat responds correctly
- [ ] Data saves properly
- [ ] Sync works (if AWS configured)

---

## 🎉 You're Ready!

Congratulations! Finance OS is now installed and configured. 

### Next Steps:
1. **Scan your first receipt** - Test the AI-powered OCR
2. **Try the chat** - Ask about your finances
3. **Explore analytics** - View your financial insights
4. **Set up goals** - Let the autopilot help you achieve them
5. **Invite friends** - Share the app (coming soon)

### Need Help?
- Check the [Quick Start Guide](QUICK_START_GUIDE.md)
- Read the [User Manual](USER_MANUAL.md) (coming soon)
- Visit [GitHub Discussions](https://github.com/your-org/nova_finance_os/discussions)

---

**Welcome to Finance OS - Your AI-Powered Financial Life OS! 🚀**

**Version:** 1.0.0  
**Last Updated:** February 10, 2026  
**Status:** ✅ Production Ready
