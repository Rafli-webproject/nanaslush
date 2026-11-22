import { Request, Response } from 'express';
import { db } from '../db';
import { orders, products } from '../db/schema';
import { eq, sql, and, gte } from 'drizzle-orm';

export const getAdminStats = async (req: Request, res: Response): Promise<void> => {
  try {
    // 1. Total Pendapatan (Status Completed)
    const revenueResult = await db.select({ total: sql<string>`SUM(${orders.totalPrice})` })
      .from(orders)
      .where(eq(orders.status, 'completed'));
    const totalRevenue = parseFloat(revenueResult[0].total || '0');

    // 2. Total Pendapatan Hari Ini
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const revenueTodayResult = await db.select({ total: sql<string>`SUM(${orders.totalPrice})` })
      .from(orders)
      .where(and(eq(orders.status, 'completed'), gte(orders.createdAt, today)));
    const todayRevenue = parseFloat(revenueTodayResult[0].total || '0');

    // 3. Total Pesanan & Pending
    const totalOrdersResult = await db.select({ count: sql<number>`COUNT(*)` }).from(orders);
    const pendingOrdersResult = await db.select({ count: sql<number>`COUNT(*)` }).from(orders).where(eq(orders.status, 'pending'));
    
    // 4. Total Produk
    const totalProductsResult = await db.select({ count: sql<number>`COUNT(*)` }).from(products);

    res.status(200).json({
      success: true,
      data: {
        totalRevenue,
        todayRevenue,
        totalOrders: totalOrdersResult[0].count,
        pendingOrders: pendingOrdersResult[0].count,
        totalProducts: totalProductsResult[0].count,
      }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Gagal mengambil statistik', error: error.message });
  }
};