# SpendWise

A beautiful personal finance tracker app built with Flutter.

**Master Your Money** - Track your expenses across different categories with an intuitive and modern UI.

## Features

- 💰 Track total balance
- 📊 Multiple spending categories (Home, College, Medicine)
- 🎨 Beautiful gradient UI
- 📱 Responsive design
- 🔥 Firebase backend integration
- 💾 Cloud Firestore database for data persistence
- 🔄 Real-time data synchronization

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone this repository
2. Navigate to the project directory:
   ```bash
   cd Spendwise
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

4. Configure Firebase:
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
   - Firebase configuration is already set up in `lib/firebase_options.dart`

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/
│   └── category_data.dart   # Data models
├── screens/
│   ├── splash_screen.dart   # Splash screen with branding
│   ├── wallet_screen.dart   # Main dashboard/wallet screen
│   ├── home_screen.dart     # Home screen
│   ├── add_expense_screen.dart  # Add expense functionality
│   ├── add_category_screen.dart # Add category functionality
│   ├── recent_screen.dart   # Recent transactions
│   └── stats_screen.dart    # Statistics view
├── services/
│   └── database_service.dart # Firebase Firestore service
├── widgets/
│   ├── category_card.dart   # Reusable category card widget
│   ├── new_category_card.dart # New category card
│   └── bottom_navbar.dart   # Bottom navigation bar
└── utils/
    └── colors.dart          # App color palette
```

## Backend Integration

### Firebase Services
- **Cloud Firestore**: NoSQL database for storing expenses and categories
- **Real-time Updates**: Automatic data synchronization across devices
- **Database Service**: Centralized service layer for all database operations

### Data Structure
- Collections for expenses and categories
- Timestamp-based tracking
- Category-based expense organization

## Screenshots

- Splash Screen: Beautiful gradient background with wallet icon
- Dashboard: Balance card with spending categories

## Color Palette

- Primary Dark: #0f1729
- Secondary Dark: #1a1f3a
- Primary Green: #3dd598
- Accent Teal: #4ecdc4
- Accent Orange: #ff8c42
- Accent Pink: #ff6b9d

## License

This project is for educational purposes.
