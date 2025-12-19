# CodeMagic iOS Build Setup for GoPayna

This repository is configured for iOS builds using CodeMagic CI/CD platform.

## Prerequisites

Before setting up CodeMagic, you need:

1. **Apple Developer Account** - Active membership required
2. **App Store Connect Account** - Access to manage your app
3. **iOS Distribution Certificate** - For code signing
4. **Provisioning Profile** - For app distribution

## CodeMagic Configuration

The `codemagic.yaml` file is already configured with:
- iOS workflow for production builds
- Debug workflow for development
- Automatic App Store Connect integration
- TestFlight distribution

## Setup Steps

### 1. CodeMagic Account Setup
1. Sign up at [codemagic.io](https://codemagic.io)
2. Connect your GitHub account
3. Add the `gopayna-mobile` repository

### 2. App Store Connect Integration
1. In CodeMagic dashboard, go to **Teams → Integrations**
2. Add **App Store Connect** integration
3. Upload your App Store Connect API key:
   - Key ID
   - Issuer ID  
   - Private Key (.p8 file)

### 3. Code Signing Setup
1. In CodeMagic dashboard, go to your app → **Code signing**
2. Upload your iOS Distribution Certificate (.p12 file)
3. Upload your Provisioning Profile
4. Or use automatic code signing (recommended)

### 4. Environment Variables
Update the following encrypted variables in `codemagic.yaml`:

```yaml
vars:
  BUNDLE_ID: "com.gopayna.app"  # Your app's bundle identifier
  APP_STORE_CONNECT_ISSUER_ID: Encrypted(...)  # From App Store Connect API key
  APP_STORE_CONNECT_KEY_IDENTIFIER: Encrypted(...)  # Key ID
  APP_STORE_CONNECT_PRIVATE_KEY: Encrypted(...)  # Private key content
  CERTIFICATE_PRIVATE_KEY: Encrypted(...)  # iOS certificate password
```

### 5. Build Configuration

The workflow will:
- Install Flutter dependencies
- Install CocoaPods dependencies  
- Set up code signing
- Build IPA file
- Upload to TestFlight (if configured)

### 6. Triggering Builds

Builds are triggered on:
- Push to `main` branch
- Push to `develop` branch  
- Push to `release/*` branches
- Pull requests

## Build Artifacts

Each successful build produces:
- **IPA file** - Ready for App Store submission
- **Build logs** - For debugging if needed

## Distribution

The workflow is configured to:
- **TestFlight**: Automatic upload for beta testing
- **App Store**: Manual upload (set `submit_to_app_store: true` when ready)

## Local Development

For local iOS development:

```bash
# Get dependencies
flutter pub get

# Install iOS pods
cd ios && pod install && cd ..

# Run on iOS simulator
flutter run -d ios

# Build for iOS (requires Mac)
flutter build ios --release
```

## Troubleshooting

### Common Issues:

1. **Code Signing Errors**
   - Ensure certificates and provisioning profiles are valid
   - Check bundle identifier matches

2. **Pod Installation Fails**
   - Clear pod cache: `cd ios && pod cache clean --all`
   - Update CocoaPods: `sudo gem install cocoapods`

3. **Build Timeout**
   - Increase `max_build_duration` in `codemagic.yaml`
   - Optimize dependencies and cache usage

### Build Status

- **Green**: Build successful, IPA ready
- **Red**: Build failed, check logs
- **Yellow**: Build in progress

## Support

For CodeMagic specific issues:
- [CodeMagic Documentation](https://docs.codemagic.io)
- [CodeMagic Support](https://codemagic.io/contact/)

For GoPayna app issues:
- Check the main repository
- Review error logs in CodeMagic dashboard