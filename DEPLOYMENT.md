# 🚀 Deployment Guide - Finance OS

## Overview

Finance OS uses automated CI/CD pipelines with GitHub Actions for professional-grade deployment to multiple platforms.

---

## 🏗️ Architecture

### Deployment Targets
- **Web**: Firebase Hosting (automatic deployment)
- **Android**: APK/AAB builds (GitHub Releases)
- **iOS**: Manual deployment via Xcode (coming soon)
- **Desktop**: Manual builds (macOS, Windows, Linux)

### CI/CD Pipeline
```
Code Push → GitHub Actions → Build → Test → Deploy → Release
```

---

## 📋 Prerequisites

### Required Secrets (GitHub Repository Settings)

Navigate to: `Settings → Secrets and variables → Actions`

Add the following secrets:

1. **GEMINI_API_KEY**
   - Your Google Nova API key
   - Get from: https://ai.google.dev/

2. **FIREBASE_TOKEN**
   - Firebase CI token for deployment
   - Generate: `firebase login:ci`

3. **FIREBASE_PROJECT_ID**
   - Your Firebase project ID
   - Find in Firebase Console

4. **CODECOV_TOKEN** (Optional)
   - For code coverage reports
   - Get from: https://codecov.io/

---

## 🌐 Web Deployment (Firebase Hosting)

### Automatic Deployment

**Triggers:**
- Push to `main` branch → Production deployment
- Push to `production` branch → Production deployment
- Pull Request → Preview deployment

**Workflow:** `.github/workflows/deploy-web.yml`

### Manual Deployment

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Build Flutter web app
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Deploy to specific project
firebase deploy --only hosting --project nova-accountant-prod
```

### Preview Deployments

Pull requests automatically get preview URLs:
```
https://nova-accountant--pr-123-xyz.web.app
```

### Custom Domain Setup

1. Go to Firebase Console → Hosting
2. Click "Add custom domain"
3. Follow DNS configuration steps
4. Update `firebase.json` if needed

---

## 📱 Android Deployment

### Automatic Build

**Triggers:**
- Push to `main` → Release APK
- Git tag `v*` → Release APK + AAB + GitHub Release
- Pull Request → Debug APK

**Workflow:** `.github/workflows/build-android.yml`

### Manual Build

```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK (for distribution)
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### Signing Configuration

Create `android/key.properties`:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-keystore>
```

Update `android/app/build.gradle.kts`:
```kotlin
signingConfigs {
    create("release") {
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
    }
}
```

### Play Store Deployment

1. Build App Bundle: `flutter build appbundle --release`
2. Go to Google Play Console
3. Create new release
4. Upload `build/app/outputs/bundle/release/app-release.aab`
5. Fill in release notes
6. Submit for review

---

## 🍎 iOS Deployment (Coming Soon)

### Manual Build

```bash
# Build iOS app
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace
```

### App Store Deployment

1. Open Xcode
2. Select "Product → Archive"
3. Upload to App Store Connect
4. Submit for review

---

## 🔄 Continuous Integration

### Workflow: `.github/workflows/ci.yml`

**Runs on:**
- Every push to `main` or `develop`
- Every pull request

**Checks:**
- ✅ Code formatting (`dart format`)
- ✅ Static analysis (`flutter analyze`)
- ✅ Unit tests (`flutter test`)
- ✅ Code coverage (Codecov)
- ✅ Build verification (web + Android)
- ✅ Security scan (Trivy)

### Local CI Checks

Run the same checks locally:

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests with coverage
flutter test --coverage

# Build for all platforms
flutter build web --debug
flutter build apk --debug
```

---

## 📦 Release Process

### Creating a Release

1. **Update version** in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1
   ```

2. **Commit changes**:
   ```bash
   git add .
   git commit -m "chore: bump version to 1.0.0"
   ```

3. **Create and push tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. **GitHub Actions automatically**:
   - Builds release APK and AAB
   - Creates GitHub Release
   - Uploads artifacts
   - Generates release notes

### Release Artifacts

After tagging, find artifacts at:
```
https://github.com/YOUR_USERNAME/nova_finance_os/releases
```

Includes:
- `app-release.apk` - Android APK
- `app-release.aab` - Android App Bundle
- Release notes (auto-generated)

---

## 🔐 Security Best Practices

### Secrets Management

✅ **DO:**
- Store API keys in GitHub Secrets
- Use environment variables
- Rotate keys regularly
- Use different keys for dev/prod

❌ **DON'T:**
- Commit API keys to repository
- Share secrets in plain text
- Use production keys in development

### Environment Variables

**In GitHub Actions:**
```yaml
env:
  GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
```

**In Flutter:**
```dart
// Use flutter_dotenv or const String.fromEnvironment
const apiKey = String.fromEnvironment('GEMINI_API_KEY');
```

---

## 📊 Monitoring & Analytics

### Build Status Badges

Add to README.md:

```markdown
![CI](https://github.com/YOUR_USERNAME/nova_finance_os/workflows/CI/badge.svg)
![Deploy Web](https://github.com/YOUR_USERNAME/nova_finance_os/workflows/Deploy%20Web/badge.svg)
![Build Android](https://github.com/YOUR_USERNAME/nova_finance_os/workflows/Build%20Android/badge.svg)
```

### Firebase Analytics

Monitor deployment metrics:
- Hosting traffic
- Error rates
- Performance metrics

Access at: https://console.firebase.google.com/

---

## 🐛 Troubleshooting

### Build Failures

**Problem:** Flutter version mismatch
```bash
# Solution: Update Flutter version in workflow
flutter-version: '3.10.8'
```

**Problem:** Missing dependencies
```bash
# Solution: Clear cache and reinstall
flutter clean
flutter pub get
```

**Problem:** Firebase deployment fails
```bash
# Solution: Regenerate Firebase token
firebase login:ci
# Add new token to GitHub Secrets
```

### Common Issues

**Issue:** APK not signed
- Add signing configuration to `build.gradle.kts`
- Store keystore securely
- Add keystore password to GitHub Secrets

**Issue:** Web app not loading
- Check `firebase.json` configuration
- Verify base-href in build command
- Check browser console for errors

**Issue:** Tests failing in CI
- Run tests locally first
- Check for environment-specific issues
- Review test logs in GitHub Actions

---

## 🚀 Advanced Deployment

### Multi-Environment Setup

**Environments:**
- Development: `develop` branch
- Staging: `staging` branch
- Production: `main` branch

**Firebase Projects:**
```json
{
  "projects": {
    "default": "nova-accountant-dev",
    "staging": "nova-accountant-staging",
    "production": "nova-accountant-prod"
  }
}
```

**Deploy to specific environment:**
```bash
firebase use staging
firebase deploy --only hosting
```

### Feature Flags

Use Firebase Remote Config:
```dart
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();
final newFeatureEnabled = remoteConfig.getBool('new_feature_enabled');
```

### A/B Testing

Use Firebase A/B Testing:
1. Create experiment in Firebase Console
2. Define variants
3. Monitor metrics
4. Roll out winner

---

## 📈 Performance Optimization

### Build Optimization

```bash
# Web: Use CanvasKit for better performance
flutter build web --web-renderer canvaskit

# Android: Enable R8 shrinking
flutter build apk --release --shrink

# Enable split APKs for smaller downloads
flutter build apk --split-per-abi
```

### Caching Strategy

**GitHub Actions:**
```yaml
- uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      build/
    key: ${{ runner.os }}-flutter-${{ hashFiles('**/pubspec.lock') }}
```

**Firebase Hosting:**
```json
{
  "headers": [
    {
      "source": "**/*.@(js|css)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "max-age=31536000"
        }
      ]
    }
  ]
}
```

---

## 📚 Additional Resources

### Documentation
- [Flutter Deployment](https://docs.flutter.dev/deployment)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Google Play Console](https://play.google.com/console)

### Tools
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [Fastlane](https://fastlane.tools/) - iOS/Android automation
- [Codemagic](https://codemagic.io/) - Flutter CI/CD platform

---

## ✅ Deployment Checklist

### Before First Deployment

- [ ] Set up Firebase project
- [ ] Configure GitHub Secrets
- [ ] Test workflows locally
- [ ] Review security settings
- [ ] Set up monitoring

### Before Each Release

- [ ] Update version number
- [ ] Run tests locally
- [ ] Update CHANGELOG.md
- [ ] Create release notes
- [ ] Tag release in Git

### After Deployment

- [ ] Verify deployment successful
- [ ] Test deployed app
- [ ] Monitor error rates
- [ ] Check analytics
- [ ] Announce release

---

## 🎯 Pro Tips

1. **Use branch protection**: Require CI checks before merging
2. **Enable auto-merge**: For dependabot PRs
3. **Set up notifications**: Get alerts for failed builds
4. **Monitor costs**: Firebase has free tier limits
5. **Document changes**: Keep CHANGELOG.md updated
6. **Test in staging**: Before production deployment
7. **Rollback plan**: Keep previous versions accessible
8. **Performance monitoring**: Use Firebase Performance
9. **Error tracking**: Integrate Sentry or Crashlytics
10. **User feedback**: Monitor app reviews and analytics

---

**Deployment Status:** ✅ Production Ready

**Last Updated:** February 2026

**Maintained by:** Finance OS Team
