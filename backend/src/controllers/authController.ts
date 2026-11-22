import { Request, Response } from 'express';
import { db } from '../db';
import { users } from '../db/schema';
import { eq } from 'drizzle-orm';
import bcrypt from 'bcrypt';
import { z } from 'zod';
import { generateToken } from '../utils/jwt';
import { formatZodError } from '../utils/validation';

// Skema Validasi Zod
const registerSchema = z.object({
  name: z.string().min(3, 'Nama minimal 3 karakter'),
  email: z.string().email('Format email tidak valid'),
  password: z.string().min(6, 'Password minimal 6 karakter'),
  role: z.enum(['admin', 'customer']).optional(),
});

const loginSchema = z.object({
  email: z.string().email('Format email tidak valid'),
  password: z.string().min(1, 'Password wajib diisi'),
});

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = registerSchema.parse(req.body);

    // Cek apakah email sudah terdaftar
    const existingUser = await db.select().from(users).where(eq(users.email, validatedData.email));
    if (existingUser.length > 0) {
      res.status(400).json({ success: false, message: 'Email sudah terdaftar' });
      return;
    }

    // Hash Password
    const hashedPassword = await bcrypt.hash(validatedData.password, 10);

    // Simpan ke database
    const newUser = await db.insert(users).values({
      name: validatedData.name,
      email: validatedData.email,
      password: hashedPassword,
      role: validatedData.role || 'customer', // Default customer
    });

    res.status(201).json({ success: true, message: 'Registrasi berhasil', data: { id: newUser[0].insertId } });
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ success: false, message: 'Validasi gagal', errors: formatZodError(error) });
      return;
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = loginSchema.parse(req.body);

    // Cari user berdasarkan email
    const user = await db.select().from(users).where(eq(users.email, validatedData.email));
    if (user.length === 0) {
      res.status(401).json({ success: false, message: 'Email atau password salah' });
      return;
    }

    // Cek Password
    const isPasswordValid = await bcrypt.compare(validatedData.password, user[0].password);
    if (!isPasswordValid) {
      res.status(401).json({ success: false, message: 'Email atau password salah' });
      return;
    }

    // Generate Token
    const token = generateToken(user[0].id, user[0].role);

    res.status(200).json({
      success: true,
      message: 'Login berhasil',
      data: { token, user: { id: user[0].id, name: user[0].name, role: user[0].role } },
    });
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ success: false, message: 'Validasi gagal', errors: formatZodError(error) });
      return;
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server', error: error.message });
  }
};