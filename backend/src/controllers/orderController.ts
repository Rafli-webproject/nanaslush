import { Request, Response } from 'express';
import { db } from '../db';
import { orders, products } from '../db/schema';
import { eq } from 'drizzle-orm';
import { z } from 'zod';
import { uploadToCloudinary } from '../utils/uploadImage';
import { formatZodError } from '../utils/validation';

const orderSchema = z.object({
  productId: z.string().regex(/^\d+$/, 'Product ID harus berupa angka'),
  quantity: z.string().regex(/^\d+$/, 'Quantity harus berupa angka'),
  notes: z.string().optional(),
});

const statusSchema = z.object({
  status: z.enum(['pending', 'processed', 'completed', 'cancelled']),
});

// 1. CREATE ORDER (Customer)
export const createOrder = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = orderSchema.parse(req.body);
    const file = req.file;
    
    // Cek produk apakah ada
    const product = await db.select().from(products).where(eq(products.id, parseInt(validatedData.productId)));
    if (product.length === 0) {
      res.status(404).json({ success: false, message: 'Produk tidak ditemukan' });
      return;
    }

    // Hitung total harga
    const quantity = parseInt(validatedData.quantity);
    const totalPrice = (parseFloat(product[0].price) * quantity).toString();

    // Upload bukti pembayaran jika ada
    let paymentProofUrl = null;
    if (file) {
      paymentProofUrl = await uploadToCloudinary(file.buffer);
    }

    const newOrder = await db.insert(orders).values({
      userId: req.user!.id, // Didapat dari token JWT
      productId: parseInt(validatedData.productId),
      quantity: quantity,
      totalPrice: totalPrice,
      notes: validatedData.notes,
      paymentProofUrl: paymentProofUrl,
    });

    res.status(201).json({ success: true, message: 'Pesanan berhasil dibuat', data: { id: newOrder[0].insertId } });
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ success: false, message: 'Validasi gagal', errors: formatZodError(error) });
      return;
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};

// 2. GET ALL ORDERS (Admin melihat semua, Customer hanya melihat miliknya)
export const getOrders = async (req: Request, res: Response): Promise<void> => {
  try {
    let orderList;
    if (req.user!.role === 'admin') {
      orderList = await db.select().from(orders);
    } else {
      orderList = await db.select().from(orders).where(eq(orders.userId, req.user!.id));
    }
    res.status(200).json({ success: true, message: 'Daftar pesanan berhasil diambil', data: orderList });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};

// 3. UPDATE STATUS (Hanya Admin)
export const updateOrderStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = parseInt(req.params.id as string);
    const validatedData = statusSchema.parse(req.body);

    await db.update(orders).set({ status: validatedData.status }).where(eq(orders.id, id));
    res.status(200).json({ success: true, message: 'Status pesanan berhasil diperbarui' });
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ success: false, message: 'Validasi gagal', errors: formatZodError(error) });
      return;
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};