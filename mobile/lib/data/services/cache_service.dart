import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String boxName = 'app_cache';
  static const String userKey = 'user_profile';
  static const String bookingKey = 'booking_schedule';
  static const String courtsKey = 'courts_data';

  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  Box get _box => Hive.box(boxName);

  Future<void> cacheData(String key, dynamic data) async {
    await _box.put(key, data);
  }

  dynamic getData(String key) {
    return _box.get(key);
  }

  Future<void> clearCache() async {
    await _box.clear();
  }
  
  // Specific cache methods
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    await cacheData(userKey, profile);
  }
  
  Map<String, dynamic>? getUserProfile() {
    final data = getData(userKey);
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> cacheCourts(List<dynamic> courts) async {
    await cacheData(courtsKey, courts);
  }
  
  List<dynamic>? getCourts() {
    final data = getData(courtsKey);
    if (data != null) {
      return List<dynamic>.from(data);
    }
    return null;
  }
}
