import 'package:flutter/material.dart';
import 'package:mobile/ui/auth/login_screen.dart';
import 'package:mobile/ui/theme/app_theme.dart';
import 'package:mobile/data/services/cache_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile/data/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCM Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
