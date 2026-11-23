import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  final _voucherController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  File? _imageFile;
  bool _isLoading = false;
  bool _isVoucherLoading = false;
  
  ImagePicker? _picker;

  int _discountPercent = 0;
  String? _appliedVoucher;

  String _deliveryMethod = 'delivery'; 
  String _paymentMethod = 'transfer'; 

  @override
  void initState() {
    super.initState();
    try {
      _picker = ImagePicker();
    } catch (e) {
      debugPrint("Gagal inisialisasi ImagePicker: $e");
    }
  }

  String _formatPrice(dynamic price) {
    final double parsedPrice = double.tryParse(price?.toString() ?? '0') ?? 0.0;
    final String priceStr = parsedPrice.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < priceStr.length; i++) {
      if ((priceStr.length - i) % 3 == 0 && i != 0) buffer.write('.');
      buffer.write(priceStr[i]);
    }
    return 'Rp $buffer';
  }

  Future<void> _pickImage() async {
    if (_picker == null) return;
    try {
      final pickedFile = await _picker!.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memilih gambar'), backgroundColor: Colors.red));
    }
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isVoucherLoading = true);
    try {
      final response = await _apiService.checkVoucher(code);
      setState(() {
        _discountPercent = response.data['data']['discountPercent'] ?? 0;
        _appliedVoucher = code;
        _isVoucherLoading = false;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voucher berhasil! Diskon $_discountPercent%'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() {
        _discountPercent = 0;
        _appliedVoucher = null;
        _isVoucherLoading = false;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher tidak valid!'), backgroundColor: Colors.red));
    }
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      if (_paymentMethod == 'transfer' && _imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap unggah bukti pembayaran transfer!'), backgroundColor: Colors.red));
        return;
      }

      setState(() => _isLoading = true);
      try {
        final double basePrice = (double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0.0) * (int.tryParse(_quantityController.text) ?? 1);
        final double discountAmount = basePrice * (_discountPercent / 100);

        await _apiService.createOrder(
          productId: int.tryParse(widget.product['id']?.toString() ?? '0') ?? 0,
          quantity: int.tryParse(_quantityController.text) ?? 1,
          notes: _notesController.text,
          paymentProofPath: _imageFile?.path ?? '', 
          deliveryMethod: _deliveryMethod,
          paymentMethod: _paymentMethod,
          customerPhone: _phoneController.text,
          address: _deliveryMethod == 'delivery' ? _addressController.text : null,
          voucherCode: _appliedVoucher,
          discountAmount: discountAmount.toString(),
        );

        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibuat!'), backgroundColor: Colors.green));
          Navigator.pop(context); 
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat pesanan.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double basePrice = (double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0.0) * (int.tryParse(_quantityController.text) ?? 1);
    final double discountAmount = basePrice * (_discountPercent / 100);
    final double finalPrice = basePrice - discountAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Form Pemesanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- INFO PRODUK (DIPERBARUI) ---
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gambar Produk
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.product['imageUrl'] != null
                            ? Image.network(
                                widget.product['imageUrl'],
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.local_drink, size: 90, color: Colors.blue),
                              )
                            : const Icon(Icons.local_drink, size: 90, color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      
                      // Detail Teks Produk
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product['name']?.toString() ?? 'Nama Produk', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatPrice(widget.product['price']), 
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 16)
                            ),
                            const SizedBox(height: 8),
                            
                            // Deskripsi Produk
                            Text(
                              widget.product['description']?.toString() ?? 'Tidak ada deskripsi untuk produk ini.', 
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Input
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Pesanan', prefixIcon: Icon(Icons.numbers)),
                onChanged: (value) => setState(() {}),
                validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Jumlah valid' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor HP Aktif', prefixIcon: Icon(Icons.phone)),
                validator: (val) => (val == null || val.length < 10) ? 'Nomor HP tidak valid' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Catatan (Opsional)', prefixIcon: Icon(Icons.notes)),
              ),
              const Divider(height: 32),

              // Pengiriman
              const Text('Metode Pengiriman', style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                leading: Icon(_deliveryMethod == 'delivery' ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.blue),
                title: const Text('Diantar ke Alamat (Delivery)'),
                onTap: () => setState(() => _deliveryMethod = 'delivery'),
              ),
              ListTile(
                leading: Icon(_deliveryMethod == 'pickup' ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.blue),
                title: const Text('Ambil di Tempat (Pickup)'),
                onTap: () => setState(() => _deliveryMethod = 'pickup'),
              ),
              
              if (_deliveryMethod == 'delivery') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Alamat Lengkap Pengiriman', prefixIcon: Icon(Icons.location_on)),
                  validator: (val) => _deliveryMethod == 'delivery' && (val == null || val.isEmpty) ? 'Alamat wajib diisi' : null,
                ),
              ],
              const Divider(height: 32),

              // Pembayaran
              const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                leading: Icon(_paymentMethod == 'transfer' ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.blue),
                title: const Text('Transfer Bank (Upload Bukti)'),
                onTap: () => setState(() => _paymentMethod = 'transfer'),
              ),
              
              // Info Rekening Bank
              if (_paymentMethod == 'transfer')
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transfer ke rekening berikut:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      SizedBox(height: 8),
                      Text('Bank BCA: 123-456-7890', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text('a.n Nana Slush UMKM', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),

              ListTile(
                leading: Icon(_paymentMethod == 'cash' ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.blue),
                title: const Text('Bayar di Tempat / Cash (COD)'),
                onTap: () => setState(() => _paymentMethod = 'cash'),
              ),

              if (_paymentMethod == 'transfer') ...[
                const SizedBox(height: 16),
                const Text('Unggah Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, size: 30, color: Colors.blue),
                              SizedBox(height: 8),
                              Text('Pilih Gambar'),
                            ],
                          ),
                  ),
                ),
              ],
              const Divider(height: 32),

              // Voucher
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _voucherController,
                      decoration: const InputDecoration(labelText: 'Kode Voucher', prefixIcon: Icon(Icons.local_offer)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 50),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: _isVoucherLoading ? null : _applyVoucher,
                      child: _isVoucherLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Pakai'),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Harga
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                  Text(_formatPrice(basePrice), style: const TextStyle(fontSize: 14)),
                ],
              ),
              if (_discountPercent > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Diskon ($_discountPercent%):', style: const TextStyle(fontSize: 14, color: Colors.green)),
                    Text('- ${_formatPrice(discountAmount)}', style: const TextStyle(fontSize: 14, color: Colors.green)),
                  ],
                ),
              ],
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Harga:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(_formatPrice(finalPrice), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Konfirmasi Pesanan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}