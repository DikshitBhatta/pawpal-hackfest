# 🐾 VitaPaw - AI-Powered Pet Care Companion

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![Gemini AI](https://img.shields.io/badge/Gemini_AI-4285F4?style=for-the-badge&logo=google)](https://makersuite.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

> **VitaPaw** is a comprehensive AI-powered pet care application that provides personalized meal planning, health tracking, and subscription management for your beloved pets.

## 📱 App Overview

VitaPaw revolutionizes pet care by combining cutting-edge AI technology with comprehensive pet management features:

### ✨ Key Features

- 🤖 **AI-Powered Meal Planning** - Personalized nutrition plans using Google Gemini AI
- 📍 **Location-Based Services** - Find nearby vets, pet stores, and services
- 🔔 **Smart Notifications** - Reminders for feeding, medication, and vet appointments
- 📸 **Pet Profile Management** - Comprehensive pet health and care tracking
- 💳 **Subscription Management** - Automated billing and delivery scheduling

### 🏗️ Architecture

- **Frontend**: Flutter (iOS & Android)
- **Backend**: Firebase (Auth, Firestore, Storage, Functions, Messaging)
- **AI Engine**: Google Gemini for personalized meal recommendations
- **Maps**: Google Maps integration for location services

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (>=3.3.1)
- **Dart SDK** (>=3.3.1)
- **Firebase CLI** (`npm install -g firebase-tools`)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development)
- **Google Firebase Project**

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/DikshitBhatta/Pet-Care-App.git
   cd pet_care
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   ```bash
   # Install Firebase CLI if not already installed
   npm install -g firebase-tools

   # Login to Firebase
   firebase login

   # Initialize Firebase in your project
   firebase init
   ```

4. **Configure API Keys**

   Copy the template file and add your API keys:
   ```bash
   cp lib/apiKey.template.dart lib/apiKey.dart
   ```

   Edit `lib/apiKey.dart` and replace with your actual keys:
   - **Google Maps API Key**: Get from [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - **Google Gemini API Key**: Get from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - **OpenAI API Key**: Get from [OpenAI Platform](https://platform.openai.com/api-keys)

5. **Firebase Configuration**

   - Download `google-services.json` from Firebase Console → Project Settings → General → Your apps → Android
   - Place it in `android/app/`
   - Download `GoogleService-Info.plist` from Firebase Console → Project Settings → General → Your apps → iOS
   - Place it in `ios/Runner/`

6. **Run the App**
   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run --flavor development
   ```

## 📂 Project Structure

```
pet_care/
├── android/                    # Android-specific files
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml
│   │   │   ├── kotlin/         # Kotlin source files
│   │   │   └── res/            # Android resources
│   │   └── google-services.json # Firebase config (not in repo)
├── ios/                        # iOS-specific files
│   ├── Runner/
│   │   ├── Info.plist         # iOS configuration
│   │   └── GoogleService-Info.plist # Firebase config (not in repo)
│   └── Podfile                # CocoaPods dependencies
├── lib/                        # Flutter source code
│   ├── main.dart              # App entry point
│   ├── apiKey.dart            # API keys (not in repo)
│   ├── firebase_options.dart  # Firebase config (not in repo)
│   ├── services/              # Business logic services
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── storage_service.dart
│   │   └── subscription_service.dart
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable UI components
│   └── models/                # Data models
├── assets/                    # Static assets
│   ├── images/               # App images
│   ├── fonts/                # Custom fonts
│   └── animations/           # Lottie animations
├── test/                     # Unit and widget tests
└── pubspec.yaml              # Flutter dependencies
```

## 🔧 Configuration

### Firebase Services Setup

1. **Authentication**
   - Enable Email/Password, Google, and Apple Sign-In
   - Configure OAuth redirect URIs

2. **Firestore Database**
   - Create collections: `users`, `pets`, `mealPlans`, `orders`
   - Set up security rules in `firestore_security_rules.txt`

3. **Cloud Storage**
   - Create buckets for pet images and documents
   - Configure storage rules
     

### Environment Variables

Create a `.env` file in the root directory:

```env
GOOGLE_MAPS_API_KEY=your_maps_api_key
GEMINI_API_KEY=your_gemini_api_key
OPENAI_API_KEY=your_openai_api_key
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run integration tests
flutter test integration_test/

# Run specific test file
flutter test test/auth_service_test.dart
```

## 📦 Build & Deployment

### Android Build
```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# App Bundle
flutter build appbundle
```

### iOS Build
```bash
# Debug build
flutter build ios

# Release build
flutter build ios --release
```

### Firebase Deployment
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy everything
firebase deploy
```

## 🔐 Security & Privacy

- **API Keys**: Never commit real API keys to version control
- **Firebase Security Rules**: Properly configured for data protection
- **User Authentication**: Secure authentication flow with multiple providers
- **Data Encryption**: All sensitive data is encrypted in transit and at rest


### Development Guidelines

- Follow Flutter best practices
- Write comprehensive tests
- Update documentation
- Ensure code quality with `flutter analyze`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Forked from**: [WaqasZafar9/Pet-Care-App](https://github.com/WaqasZafar9/Pet-Care-App)
- **Built with**: Flutter, Firebase, Google Gemini AI
- **Icons**: Custom designed for VitaPaw
- **UI/UX**: Modern and intuitive pet care interface

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/DikshitBhatta/Pet-Care-App/issues)
- **Discussions**: [GitHub Discussions](https://github.com/DikshitBhatta/Pet-Care-App/discussions)
- **Email**: dikshitbhatta2060@gmail.com

## 🔄 Version History

### v1.0.1 (Current)
- ✅ AI-powered meal planning
- ✅ Location-based services
- ✅ Firebase integration
- ✅ Cross-platform support (iOS & Android)
- ✅ Subscription management
- ✅ Pet profile management

---

**Made with ❤️ for pet lovers worldwide**

🐕 🐱 🐾
