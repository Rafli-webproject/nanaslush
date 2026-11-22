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

  // ==========================================
  // --- FITUR AUTHENTICATION ---
  // ==========================================
  
  Future<Response> register(String name, String email, String password, String role) async {
    return await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  // ==========================================
  // --- FITUR PRODUK (PUBLIC & ADMIN) ---
  // ==========================================

  // Ambil daftar produk (Public)
  Future<Response> getProducts() async {
    return await _dio.get('/products');
  }

  // Tambah Produk (Admin)
  Future<Response> createProduct({
    required String name,
    required String description,
    required String price,
    required String stock,
    required String imagePath,
  }) async {
    FormData formData = FormData.fromMap({
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image': await MultipartFile.fromFile(imagePath, filename: 'product.jpg'),
    });
    return await _dio.post('/products', data: formData);
  }

  // Edit Produk (Admin)
  Future<Response> updateProduct({
    required int id,
    required String name,
    required String description,
    required String price,
    required String stock,
    String? imagePath, // Opsional, jika admin ingin ganti gambar
  }) async {
    FormData formData = FormData.fromMap({
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      if (imagePath != null) 
        'image': await MultipartFile.fromFile(imagePath, filename: 'product.jpg'),
    });
    return await _dio.put('/products/$id', data: formData);
  }

  // Hapus Produk (Admin)
  Future<Response> deleteProduct(int id) async {
    return await _dio.delete('/products/$id');
  }

  // ==========================================
  // --- FITUR PESANAN (CUSTOMER & ADMIN) ---
  // ==========================================

  // Buat Pesanan (Customer)
  Future<Response> createOrder({
    required int productId,
    required int quantity,
    required String notes,
    required String paymentProofPath,
  }) async {
    FormData formData = FormData.fromMap({
      'productId': productId.toString(),
      'quantity': quantity.toString(),
      'notes': notes,
      'paymentProof': await MultipartFile.fromFile(paymentProofPath, filename: 'bukti_pembayaran.jpg'),
    });

    return await _dio.post('/orders', data: formData);
  }

  // Lihat Daftar Pesanan (Admin melihat semua, Customer melihat miliknya)
  Future<Response> getOrders() async {
    return await _dio.get('/orders');
  }
}