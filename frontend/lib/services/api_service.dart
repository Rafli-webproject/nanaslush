import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Gunakan 10.0.2.2 jika pakai Emulator Android, atau localhost jika pakai Web/Windows
  static const String baseUrl = 'http://10.0.2.2:3000/api'; 
  
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

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
      'name': name, 'email': email, 'password': password, 'role': role,
    });
  }

  Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email, 'password': password,
    });
  }

  // ==========================================
  // --- FITUR USER / PROFIL ---
  // ==========================================
  Future<Response> updateProfile({required String name, String? password}) async {
    return await _dio.put('/users/profile', data: {
      'name': name,
      if (password != null && password.isNotEmpty) 'password': password,
    });
  }

  // ==========================================
  // --- FITUR PRODUK (PUBLIC & ADMIN) ---
  // ==========================================
  Future<Response> getProducts() async {
    return await _dio.get('/products');
  }

  Future<Response> createProduct({
    required String name,
    required String description,
    required String price,
    required String stock,
    required String imagePath,
  }) async {
    FormData formData = FormData.fromMap({
      'name': name, 'description': description, 'price': price, 'stock': stock,
      'image': await MultipartFile.fromFile(imagePath, filename: 'product.jpg'),
    });
    return await _dio.post('/products', data: formData);
  }

  Future<Response> updateProduct({
    required int id,
    required String name,
    required String description,
    required String price,
    required String stock,
    String? imagePath,
  }) async {
    FormData formData = FormData.fromMap({
      'name': name, 'description': description, 'price': price, 'stock': stock,
      if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath, filename: 'product.jpg'),
    });
    return await _dio.put('/products/$id', data: formData);
  }

  Future<Response> deleteProduct(int id) async {
    return await _dio.delete('/products/$id');
  }

  // ==========================================
  // --- FITUR PESANAN (CUSTOMER & ADMIN) ---
  // ==========================================
  Future<Response> createOrder({
    required int productId, 
    required int quantity, 
    required String notes, 
    required String paymentProofPath,
    required String deliveryMethod, 
    required String paymentMethod, 
    required String customerPhone,
    String? address, 
    String? voucherCode, 
    String? discountAmount
  }) async {
    FormData formData = FormData.fromMap({
      'productId': productId.toString(), 
      'quantity': quantity.toString(), 
      'notes': notes,
      'deliveryMethod': deliveryMethod,
      'paymentMethod': paymentMethod,
      'customerPhone': customerPhone,
      
      if (address != null && address.isNotEmpty) 'address': address,
      if (paymentProofPath.isNotEmpty) 'paymentProof': await MultipartFile.fromFile(paymentProofPath, filename: 'bukti.jpg'),
      
      // Menggunakan null-aware marker (?) untuk menghindari warning
      'voucherCode': ?voucherCode, 
      'discountAmount': ?discountAmount,
    });
    return await _dio.post('/orders', data: formData);
  }

  Future<Response> getOrders() async {
    return await _dio.get('/orders');
  }

  Future<Response> updateOrderStatus(int id, String status) async {
    return await _dio.put('/orders/$id/status', data: {'status': status});
  }

  // ==========================================
  // --- FITUR VOUCHER & STATISTIK ---
  // ==========================================
  Future<Response> checkVoucher(String code) async {
    return await _dio.get('/vouchers/$code');
  }

  Future<Response> getAdminStats() async {
    return await _dio.get('/stats');
  }
}