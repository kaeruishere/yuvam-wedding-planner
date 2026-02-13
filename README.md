# Yuvam 🏠

**Yuvam** (Turkish for "My Nest") is a comprehensive mobile application designed for couples to plan their future together. From wedding preparations to daily tasks and financial tracking, Yuvam helps partners stay synchronized and organized.

## ✨ Features

- **❤️ Relationship & Event Tracking**: 
  - Dynamic countdowns to special events (Engagement, Henna Night, Wedding).
  - Shared dashboard for couples.
- **📝 Shared Lists**:
  - **To-Do List**: Collaborative task management with urgency indicators.
  - **Shopping List**: Track items to buy for your new home.
- **💰 Financial Management**:
  - Track wedding expenses and remaining debts.
  - Visualize financial status with a shared wallet.
- **💌 Motivational Notes**: 
  - Leave sweet notes and messages for your partner on the dashboard.
- **🎨 Modern UI/UX**:
  - Beautiful, clean interface with Light and Dark mode support.
  - Localized in **English** and **Turkish**.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend**: [Firebase](https://firebase.google.com/)
  - **Authentication**: Secure user login and signup.
  - **Firestore**: Real-time database for syncing data between partners.
  - **Storage**: Media storage for profile photos.
  - **Cloud Functions & Messaging**: Push notifications for updates.
- **State Management**: Provider

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A valid [Firebase Project](https://console.firebase.google.com/).

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/yuvam.git
   cd yuvam
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - You need to generate `firebase_options.dart` for your project.
   - Install the FlutterFire CLI:
     ```bash
     dart pub global activate flutterfire_cli
     ```
   - Run configure command:
     ```bash
     flutterfire configure
     ```
   - Follow the prompts to select your Firebase project and platforms.

4. **Run the app**:
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── constants/       # App-wide constants (colors, text)
├── models/          # Data models (Task, Service, Item)
├── providers/       # State management (Theme, Language)
├── screens/         # UI Screens
│   ├── auth/        # Login/Signup screens
│   ├── dashboard_screen.dart
│   └── ...
├── services/        # Firebase & Business Logic
└── main.dart        # Entry point
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
