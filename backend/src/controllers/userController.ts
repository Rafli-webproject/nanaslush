import { Request, Response } from 'express';
import { db } from '../db';
import { users } from '../db/schema';
import { eq } from 'drizzle-orm';
import { z } from 'zod';
import bcrypt from 'bcrypt';
import { formatZodError } from '../utils/validation';

const updateProfileSchema = z.object({
  name: z.string().min(3, 'Nama minimal 3 karakter'),
  password: z.string().min(6, 'Password minimal 6 karakter').optional().or(z.literal('')),
});

export const updateProfile = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = updateProfileSchema.parse(req.body);
    const userId = req.user!.id;

    const updateData: any = { name: validatedData.name };

    // Jika user mengisi password baru, lakukan hash
    if (validatedData.password && validatedData.password !== '') {
      updateData.password = await bcrypt.hash(validatedData.password, 10);
    }

    await db.update(users).set(updateData).where(eq(users.id, userId));

    res.status(200).json({ success: true, message: 'Profil berhasil diperbarui' });
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ success: false, message: 'Validasi gagal', errors: formatZodError(error) });
      return;
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};