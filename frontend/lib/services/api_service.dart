import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Gunakan 10.0.2.2 jika pakai Emulator Android, atau localhost jika pakai Web/Windows
  static const String baseUrl = 'http://10.0.2.2:3000/api'; 
  
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // Menyisipkan Token JWT secara otomatis jika user sudah login
  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // Fungsi Register
  Future<Response> register(String name, String email, String password, String role) async {
    return await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  // Fungsi Login
  Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }
}