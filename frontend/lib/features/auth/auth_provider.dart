import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _token;
  String? _role;
  String? _userName;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get role => _role;
  String? get userName => _userName;

  final ApiService _apiService = ApiService();

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    _userName = prefs.getString('userName');
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      final data = response.data['data'];
      
      _token = data['token'];
      _role = data['user']['role'];
      _userName = data['user']['name'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('role', _role!);
      await prefs.setString('userName', _userName!);

      _isLoading = false;
      notifyListeners(); // Memicu AuthGate untuk pindah halaman
      return null; 
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.toString().contains('401')) return 'Email atau password salah';
      return 'Terjadi kesalahan koneksi';
    }
  }

  Future<String?> register(String name, String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.register(name, email, password, role);
      _isLoading = false;
      notifyListeners();
      return null; 
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.toString().contains('400')) return 'Email sudah terdaftar';
      return 'Terjadi kesalahan koneksi';
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = null;
    _role = null;
    _userName = null;
    notifyListeners();
  }
}