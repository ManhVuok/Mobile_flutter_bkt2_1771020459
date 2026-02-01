import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  // Automatically detect platform:
  // - Android Emulator: 10.0.2.2
  // - Web/iOS/Other: localhost
  static String get baseUrl {
    // Luôn dùng VPS để test
    return 'https://pcm-bkt2.duckdns.org';
    
    // Build Production (VPS + Domain)
    // if (kReleaseMode) {
    //   return 'https://pcm-bkt2.duckdns.org'; 
    // }
    // // Chạy trên Emulator kiểm thử
    // if (!kIsWeb && Platform.isAndroid) {
    //   return 'http://10.0.2.2:5020';
    // }
    // return 'http://localhost:5020';
  }

  static String get apiUrl => '$baseUrl/api';
  static String get hubUrl => '$baseUrl/pcmHub';
}
