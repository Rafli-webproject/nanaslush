import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await _apiService.getOrders();
      setState(() {
        _orders = response.data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil riwayat pesanan';
        _isLoading = false;
      });
    }
  }

  String _formatPrice(dynamic price) {
    final double parsedPrice = double.parse(price.toString());
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(parsedPrice);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processed': return Colors.blue;
      case 'delivering': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  // --- FITUR DETAIL PESANAN & KONTAK ADMIN ---
  void _showDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 24, left: 24, right: 24
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detail Pesanan #${order['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Text('Status: ${order['status'].toString().toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(order['status']))),
              const SizedBox(height: 8),
              Text('Metode Pengiriman: ${order['deliveryMethod'] == 'delivery' ? 'Diantar ke Alamat' : 'Ambil di Tempat'}'),
              Text('Metode Pembayaran: ${order['paymentMethod'] == 'transfer' ? 'Transfer Bank' : 'Cash / Bayar di Tempat'}'),
              
              if (order['address'] != null) ...[
                const SizedBox(height: 8),
                Text('Alamat: ${order['address']}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              
              const SizedBox(height: 24),
              const Text('Butuh bantuan atau ada kendala?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  // Simulasi membuka WhatsApp
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Membuka WhatsApp Admin: 0812-3456-7890'), backgroundColor: Colors.green)
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Hubungi Admin via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _orders.isEmpty
                  ? const Center(child: Text('Belum ada pesanan.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final statusColor = _getStatusColor(order['status']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          // Membuat Card bisa diklik
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showDetail(order),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Pesanan #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          order['status'].toString().toUpperCase(),
                                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_formatDate(order['createdAt'].toString()), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${order['paymentMethod'] == 'cash' ? 'COD' : 'Transfer'} | ${order['deliveryMethod'] == 'delivery' ? 'Diantar' : 'Pickup'}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                                      Text(_formatPrice(order['totalPrice']), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}