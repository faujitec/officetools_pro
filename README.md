# Office Tools Pro - Flutter Android

This is the Flutter Android version of the Office Tools Pro application.

## Features
- **AI Scanner**: Uses Gemini 1.5 Flash to extract text from documents.
- **Home Dashboard**: Bento-grid style navigation.
- **Offline Files**: Integrated file management (coming soon to Dart port).

## Setup Instructions

1.  **Dependencies**:
    Run `flutter pub get` to install all packages.

2.  **API Configuration**:
    The app uses the Gemini API. When running or building, you must provide your API key:
    ```bash
    flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
    ```

3.  **Build Android APK**:
    ```bash
    flutter build apk --dart-define=GEMINI_API_KEY=your_api_key_here
    ```

## Project Structure
- `lib/services/gemini_service.dart`: AI logic.
- `lib/screens/`: UI screens (Home, Scanner).
- `lib/models/`: Data structures.
