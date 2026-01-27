import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  // Automatically detect platform:
  // - Android Emulator: 10.0.2.2
  // - Web/iOS/Other: localhost
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://api.yourdomain.com'; // Replace with production URL
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5099';
    }
    return 'http://localhost:5099';
  }

  static String get apiUrl => '$baseUrl/api';
  static String get hubUrl => '$baseUrl/pcmHub';
}
