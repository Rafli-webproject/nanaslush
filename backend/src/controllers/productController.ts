import { Request, Response } from 'express';
import { db } from '../db';
import { products } from '../db/schema';
import { eq } from 'drizzle-orm';
import { z } from 'zod';
import { uploadToCloudinary } from '../utils/uploadImage';
import { formatZodError } from '../utils/validation';

const productSchema = z.object({
  name: z.string().min(3, 'Nama produk minimal 3 karakter'),
  description: z.string().optional(),
  price: z.string().regex(/^\d+(\.\d{1,2})?$/, 'Format harga tidak valid'),
  stock: z.string().regex(/^\d+$/, 'Stok harus berupa angka'),
});

// 1. CREATE (Admin)
export const createProduct = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = productSchema.parse(req.body);
    const file = req.file;
    let imageUrl = null;

    if (file) {
      imageUrl = await uploadToCloudinary(file.buffer);
    }

    const newProduct = await db.insert(products).values({
      name: validatedData.name,
      description: validatedData.description,
      price: validatedData.price,
      stock: parseInt(validatedData.stock),
      imageUrl: imageUrl,
      createdBy: req.user!.id,
    });

    res.status(201).json({ success: true, message: 'Produk berhasil ditambahkan', data: { id: newProduct[0].insertId } });
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ success: false, message: 'Validasi gagal', errors: formatZodError(error) });
      return;
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};

// 2. READ ALL (Public/Customer/Admin)
export const getAllProducts = async (req: Request, res: Response): Promise<void> => {
  try {
    const allProducts = await db.select().from(products);
    res.status(200).json({ success: true, message: 'Daftar produk berhasil diambil', data: allProducts });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};

// 3. READ BY ID
export const getProductById = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = parseInt(req.params.id as string);
    const product = await db.select().from(products).where(eq(products.id, id));
    
    if (product.length === 0) {
      res.status(404).json({ success: false, message: 'Produk tidak ditemukan' });
      return;
    }
    res.status(200).json({ success: true, message: 'Detail produk berhasil diambil', data: product[0] });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};

// 4. UPDATE (Admin)
export const updateProduct = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = parseInt(req.params.id as string);
    const validatedData = productSchema.parse(req.body);
    const file = req.file;
    let imageUrl = undefined;

    if (file) {
      imageUrl = await uploadToCloudinary(file.buffer);
    }

    const updated = await db.update(products).set({
      name: validatedData.name,
      description: validatedData.description,
      price: validatedData.price,
      stock: parseInt(validatedData.stock),
      ...(imageUrl && { imageUrl }), // Hanya update gambar jika ada file baru
    }).where(eq(products.id, id));

    res.status(200).json({ success: true, message: 'Produk berhasil diperbarui' });
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ success: false, message: 'Validasi gagal', errors: formatZodError(error) });
      return;
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};

// 5. DELETE (Admin)
export const deleteProduct = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = parseInt(req.params.id as string);
    await db.delete(products).where(eq(products.id, id));
    res.status(200).json({ success: true, message: 'Produk berhasil dihapus' });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};