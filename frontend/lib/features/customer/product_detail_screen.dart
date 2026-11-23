import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  String _formatPrice(dynamic price) {
    final double parsedPrice = double.tryParse(price?.toString() ?? '0') ?? 0.0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(parsedPrice);
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan nilai stock aman
    final int stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            product['imageUrl'] != null
                ? Image.network(product['imageUrl'], width: double.infinity, height: 300, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 300, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.local_drink, size: 100, color: Colors.grey))))
                : Container(height: 300, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.local_drink, size: 100, color: Colors.grey))),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? 'Nama Produk', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_formatPrice(product['price']), style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Sisa Stok: $stock', style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 32),
                  const Text('Deskripsi Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product['description'] ?? 'Tidak ada deskripsi untuk produk ini.', style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 40),
                  
                  // Tombol Pesan
                  ElevatedButton(
                    onPressed: stock <= 0 ? null : () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(product: product)));
                    },
                    child: Text(stock <= 0 ? 'Stok Habis' : 'Pesan Sekarang'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}