# Events Platform - Frontend

A Flutter-based web and mobile application for managing sports competitions, athletes, and race results.

## Features

- **Competition Management**: Create and manage multiple competitions and events
- **Athlete Registration**: Register athletes with QR code support for quick check-ins
- **Club Management**: Organize athletes by clubs and manage club details
- **Race Management**: Create races, assign crews, and track results in real-time
- **Live Results**: Display and update race results with timing information
- **QR Code Scanner**: Mobile scanner for athlete check-in and verification
- **Multi-language Support**: Internationalization ready
- **PDF Generation**: Export crew lists and results as PDF documents
- **Excel/CSV Export**: Export athlete and result data in multiple formats
- **Responsive Design**: Works on desktop, tablet, and mobile devices

## Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart (SDK >=2.18.6 <3.0.0)
- **State Management**: Stateful widgets with Controllers
- **HTTP Client**: http ^1.0.0
- **Key Dependencies**:
  - `mobile_scanner`: QR code scanning functionality
  - `printing` & `pdf`: PDF generation and printing
  - `file_picker`: File upload functionality
  - `excel` & `csv`: Data export capabilities
  - `url_launcher`: External link handling
  - `image_picker`: Photo upload for athletes

## Project Structure

```
lib/
├── config/           # App configuration (version, etc.)
├── src/
│   ├── administration/  # Admin panel for events and disciplines
│   ├── athletes/        # Athlete management
│   ├── clubs/          # Club management
│   ├── crews/          # Crew management and printing
│   ├── races/          # Race management and results
│   ├── teams/          # Team functionality
│   ├── users/          # User management
│   ├── model/          # Data models
│   ├── localization/   # i18n support
│   ├── qr_scanner/     # QR code scanning
│   ├── services/       # Business logic
│   └── widgets/        # Reusable UI components
└── main.dart           # Application entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart SDK >=2.18.6
- Web browser (for web development)
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository:
```bash
git clone [repository-url]
cd EurocupFrontEnd
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
# For web
flutter run -d chrome

# For mobile
flutter run
```

### Building for Production

```bash
# Web build with custom base path
flutter build web --release --base-href "/web/"

# Android build
flutter build apk --release

# iOS build
flutter build ios --release
```

## Deployment

The project includes GitHub Actions for automatic deployment:
- Pushes to `release` branch trigger automatic build and FTP deployment
- Web app is deployed to `events.motion.rs/public/web/`

## Version Management

Current version: 0.5.0

Version configuration is located in `lib/config/app_version.dart`. The version is displayed on the login page footer.

## API Integration

The frontend connects to a Laravel backend API. API endpoints are configured in `lib/src/api_helper.dart`.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Author

**Zoran Trandafilovic**

## License

This project is proprietary software. All rights reserved.