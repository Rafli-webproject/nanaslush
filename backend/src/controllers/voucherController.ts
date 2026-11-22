import { Request, Response } from 'express';
import { db } from '../db';
import { vouchers } from '../db/schema';
import { eq, and } from 'drizzle-orm';

export const checkVoucher = async (req: Request, res: Response): Promise<void> => {
  try {
    const code = (req.params.code as string).toUpperCase();
    const voucher = await db.select().from(vouchers).where(
      and(eq(vouchers.code, code), eq(vouchers.isActive, true))
    );

    if (voucher.length === 0) {
      res.status(404).json({ success: false, message: 'Voucher tidak valid atau sudah kedaluwarsa' });
      return;
    }

    res.status(200).json({ 
      success: true, 
      message: 'Voucher berhasil diterapkan', 
      data: { discountPercent: voucher[0].discountPercent } 
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server' });
  }
};