import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isLoading = false;
  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.product!['name'];
      _descController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price'];
      _stockController.text = widget.product!['stock'].toString();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (!_isEditMode && _imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gambar produk wajib diunggah!'), backgroundColor: Colors.red));
        return;
      }

      setState(() => _isLoading = true);
      try {
        if (_isEditMode) {
          await _apiService.updateProduct(
            id: widget.product!['id'], name: _nameController.text, description: _descController.text,
            price: _priceController.text, stock: _stockController.text, imagePath: _imageFile?.path,
          );
        } else {
          await _apiService.createProduct(
            name: _nameController.text, description: _descController.text,
            price: _priceController.text, stock: _stockController.text, imagePath: _imageFile!.path,
          );
        }
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data disimpan!'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan produk.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Produk' : 'Tambah Produk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : _isEditMode && widget.product!['imageUrl'] != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.product!['imageUrl'], fit: BoxFit.cover))
                          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey), SizedBox(height: 8), Text('Pilih Gambar')]),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nama Produk'), validator: (val) => val!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Harga (Angka)'), keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stok'), keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: _isLoading ? null : _submit, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan')),
            ],
          ),
        ),
      ),
    );
  }
}