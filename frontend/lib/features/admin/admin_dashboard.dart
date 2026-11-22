import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'product_form_screen.dart';
import 'admin_order_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _products = [];
  int _totalProducts = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final productRes = await _apiService.getProducts();
      final orderRes = await _apiService.getOrders();
      
      final products = productRes.data['data'];
      final orders = orderRes.data['data'];

      double revenue = 0;
      for (var order in orders) {
        if (order['status'] == 'completed') revenue += double.parse(order['totalPrice'].toString());
      }

      setState(() {
        _products = products;
        _totalProducts = products.length;
        _totalOrders = orders.length;
        _totalRevenue = revenue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.deleteProduct(id);
      _fetchDashboardData();
    }
  }

  String _formatPrice(dynamic price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(double.parse(price.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrderScreen()));
              _fetchDashboardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildStatCard('Pendapatan', _formatPrice(_totalRevenue), Colors.green),
                      const SizedBox(width: 8),
                      _buildStatCard('Pesanan', _totalOrders.toString(), Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatCard('Produk', _totalProducts.toString(), Colors.orange),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: product['imageUrl'] != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(product['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)) : const Icon(Icons.local_drink, size: 60),
                          title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${_formatPrice(product['price'])} | Stok: ${product['stock']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () async {
                                final refresh = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)));
                                if (refresh == true) _fetchDashboardData();
                              }),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(product['id'])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final refresh = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));
          if (refresh == true) _fetchDashboardData();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.5))),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}