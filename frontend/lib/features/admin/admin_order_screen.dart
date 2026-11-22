import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});
  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getOrders();
      setState(() {
        _orders = response.data['data'];
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'all') {
      _filteredOrders = _orders;
    } else {
      _filteredOrders = _orders.where((o) => o['status'] == _selectedFilter).toList();
    }
  }

  String _formatPrice(dynamic price) {
    final double parsedPrice = double.parse(price.toString());
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(parsedPrice);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processed': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    try {
      await _apiService.updateOrderStatus(orderId, newStatus);
      _fetchOrders();
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status diubah'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal ubah status'), backgroundColor: Colors.red));
    }
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pesanan #${order['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Customer: ${order['customerName']}'),
              Text('Produk: ${order['productName']} (Qty: ${order['quantity']})'),
              Text('Total: ${_formatPrice(order['totalPrice'])}'),
              if (order['notes'] != null) Text('Catatan: ${order['notes']}'),
              const Divider(height: 24),
              const Text('Bukti Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (order['paymentProofUrl'] != null)
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(order['paymentProofUrl'], height: 200, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Text('Gagal muat gambar'))),
              const SizedBox(height: 24),
              const Text('Ubah Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['pending', 'processed', 'completed', 'cancelled'].map((status) {
                  return ChoiceChip(
                    label: Text(status.toUpperCase()),
                    selected: order['status'] == status,
                    onSelected: (selected) { if (selected) _updateStatus(order['id'], status); },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pesanan')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['all', 'pending', 'processed', 'completed', 'cancelled'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter.toUpperCase()),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() { _selectedFilter = filter; _applyFilter(); });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? const Center(child: Text('Tidak ada pesanan.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          final statusColor = _getStatusColor(order['status']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () => _showOrderDetail(order),
                              title: Text('${order['customerName']} - ${order['productName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Total: ${_formatPrice(order['totalPrice'])}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor)),
                                child: Text(order['status'].toString().toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}