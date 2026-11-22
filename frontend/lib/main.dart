import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/customer/customer_home.dart';
import 'features/admin/admin_dashboard.dart'; // Import Dashboard Admin

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadToken()),
      ],
      child: const NanaSlushApp(),
    ),
  );
}

class NanaSlushApp extends StatelessWidget {
  const NanaSlushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nana Slush',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

// Class untuk mengecek apakah user sudah login atau belum
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Tampilkan loading saat memuat token dari local storage
    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Jika sudah login, arahkan ke halaman sesuai Role
    if (authProvider.isAuthenticated) {
      if (authProvider.role == 'customer') {
        return const CustomerHome(); 
      } else {
        return const AdminDashboard(); // Arahkan Admin ke Dashboard
      }
    }

    // Jika belum login, arahkan ke LoginScreen
    return const LoginScreen();
  }
}