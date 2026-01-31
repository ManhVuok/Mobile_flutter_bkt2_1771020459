import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/data/services/auth_service.dart';
import 'package:mobile/data/services/cache_service.dart';

class UserProvider extends ChangeNotifier {
  String _name = 'Vợt Thủ';
  String _role = 'Member';
  String _tier = 'Standard';
  double _walletBalance = 0.0;
  String _avatarUrl = '';
  
  String get name => _name;
  String get role => _role;
  String get tier => _tier;
  double get walletBalance => _walletBalance;
  String get avatarUrl => _avatarUrl;

  final _storage = const FlutterSecureStorage();

  Future<void> loadUser() async {
    // Try cache first (Offline)
    final cached = CacheService().getUserProfile();
    if (cached != null) {
        _name = cached['name'] ?? _name;
        _role = cached['role'] ?? _role;
        _tier = cached['tier'] ?? _tier;
        notifyListeners();
    }

    // Load from storage
    _name = await _storage.read(key: 'user_name') ?? _name;
    _role = await _storage.read(key: 'user_role') ?? _role;
    _tier = await _storage.read(key: 'user_tier') ?? _tier;
    notifyListeners();

    // Fetch from API (Online) via AuthService or ProfileService if needed
    // For now we assume typical flow updates storage
  }

  void updateUser({String? name, String? role, String? tier}) {
    if (name != null) _name = name;
    if (role != null) _role = role;
    if (tier != null) _tier = tier;
    notifyListeners();
  }

  void updateBalance(double balance) {
    _walletBalance = balance;
    notifyListeners();
  }
}
