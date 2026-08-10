import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/mesas/mesas_screen.dart';
import 'presentation/admin/admin_screen.dart';

void main() {
  runApp(const OrderSoftApp());
}

class OrderSoftApp extends StatelessWidget {
  const OrderSoftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrderSoft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/mesas': (context) => const MesasScreen(),
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}
