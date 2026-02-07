# Password Manager App

A cross-platform Flutter application that implements a secure password manager client with Argon2 password hashing.

## Features

- ✅ Cross-platform support (iOS, Android, Web, Windows, macOS, Linux)
- 🔐 Secure password hashing with Argon2id
- 🔑 Automatic user registration and login
- 📦 Vault data retrieval
- 🎨 Modern Material Design 3 UI

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)

## Installation

1. Clone or download this project
2. Navigate to the project directory
3. Install dependencies:

```bash
flutter pub get
```

## Running the App

### Android/iOS
```bash
flutter run
```

### Web
```bash
flutter run -d chrome
```

### Desktop (Windows, macOS, Linux)
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## Project Structure

```
lib/
├── main.dart                    # Main app entry point and UI
└── services/
    └── auth_service.dart        # Authentication service with API calls
```

## How It Works

1. **User Input**: Enter username and password
2. **Registration**: If user doesn't exist, automatically registers with:
   - Random 16-byte salt
   - Argon2id password derivation (time_cost=3, memory_cost=128MB, parallelism=4)
3. **Login**: Derives password verifier and authenticates
4. **Vault Access**: Retrieves and displays vault data using the authentication token

## Security Features

- **Argon2id**: Memory-hard password hashing algorithm
- **Salt**: Random 16-byte salt per user
- **Verifier**: Never sends plain password over network
- **Token**: JWT-style authentication token for API calls

## API Endpoints

The app communicates with:
- `GET /auth_salt/{username}` - Get user's salt
- `POST /register` - Register new user
- `POST /login` - Authenticate user
- `GET /vault` - Fetch vault data

## Configuration

To change the API base URL, edit the `baseUrl` constant in `lib/services/auth_service.dart`:

```dart
static const String baseUrl = 'https://your-server-url.com';
```

## Dependencies

- `http` - HTTP requests
- `argon2` - Password hashing
- `flutter` - UI framework

## Platform-Specific Notes

### Web
- CORS must be enabled on the server
- Uses browser's secure random number generator

### Mobile (iOS/Android)
- Requires internet permission
- Add to `AndroidManifest.xml` (Android):
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```

### Desktop
- No additional configuration required

## Troubleshooting

### CORS Issues (Web)
If you get CORS errors on web, ensure your server has CORS headers enabled:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST
Access-Control-Allow-Headers: Authorization, Content-Type
```

### Certificate Issues
For development with self-signed certificates, you may need to configure certificate validation.

## License

This is a sample application. Use at your own risk.