import { Request, Response } from 'express';
import { db } from '../db';
import { orders, products, users } from '../db/schema';
import { eq } from 'drizzle-orm';
import { z } from 'zod';
import { uploadToCloudinary } from '../utils/uploadImage';
import { formatZodError } from '../utils/validation';

const orderSchema = z.object({
  productId: z.string().regex(/^\d+$/),
  quantity: z.string().regex(/^\d+$/),
  notes: z.string().optional(),
  voucherCode: z.string().optional(),
  discountAmount: z.string().optional(),
});

const statusSchema = z.object({
  status: z.enum(['pending', 'processed', 'delivering', 'completed', 'cancelled']),
});

export const createOrder = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = orderSchema.parse(req.body);
    const file = req.file;
    
    const product = await db.select().from(products).where(eq(products.id, parseInt(validatedData.productId)));
    if (product.length === 0) {
      res.status(404).json({ success: false, message: 'Produk tidak ditemukan' });
      return;
    }

    const quantity = parseInt(validatedData.quantity);
    const currentStock = product[0].stock;

    if (currentStock < quantity) {
      res.status(400).json({ success: false, message: `Stok tidak mencukupi. Sisa stok: ${currentStock}` });
      return;
    }

    const totalPrice = (parseFloat(product[0].price) * quantity).toString();

    let paymentProofUrl = null;
    if (file) {
      paymentProofUrl = await uploadToCloudinary(file.buffer);
    }

    const newOrder = await db.insert(orders).values({
      userId: req.user!.id,
      productId: parseInt(validatedData.productId),
      quantity: quantity,
      totalPrice: totalPrice,
      notes: validatedData.notes,
      paymentProofUrl: paymentProofUrl,
      voucherCode: validatedData.voucherCode || null,
      discountAmount: validatedData.discountAmount || '0',
    });

    // Potong Stok Otomatis
    await db.update(products)
      .set({ stock: currentStock - quantity })
      .where(eq(products.id, parseInt(validatedData.productId)));

    res.status(201).json({ success: true, message: 'Pesanan berhasil dibuat', data: { id: newOrder[0].insertId } });
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ success: false, message: 'Validasi gagal', errors: formatZodError(error) });
      return;
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};

export const getOrders = async (req: Request, res: Response): Promise<void> => {
  try {
    if (req.user!.role === 'admin') {
      const orderList = await db.select({
        id: orders.id,
        quantity: orders.quantity,
        totalPrice: orders.totalPrice,
        status: orders.status,
        notes: orders.notes,
        paymentProofUrl: orders.paymentProofUrl,
        createdAt: orders.createdAt,
        customerName: users.name,
        productName: products.name,
      })
      .from(orders)
      .leftJoin(users, eq(orders.userId, users.id))
      .leftJoin(products, eq(orders.productId, products.id));

      res.status(200).json({ success: true, message: 'Daftar pesanan berhasil diambil', data: orderList });
    } else {
      const orderList = await db.select().from(orders).where(eq(orders.userId, req.user!.id));
      res.status(200).json({ success: true, message: 'Daftar pesanan berhasil diambil', data: orderList });
    }
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};

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