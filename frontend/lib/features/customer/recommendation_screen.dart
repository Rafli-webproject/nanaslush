import 'package:flutter/material.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spesial Untukmu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.purple, Colors.blue]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.yellow, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Diskon 20% Untuk Pembelian Pertamamu! Gunakan kode: NANA20',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Minuman Terlaris', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Di sini nanti bisa diisi list produk yang di-hardcode atau diambil dari API terpisah
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
                title: const Text('Nanaslush Frost'),
                subtitle: const Text('Paling banyak dipesan minggu ini!'),
                trailing: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () {}),
              ),
            )
          ],
        ),
      ),
    );
  }
}