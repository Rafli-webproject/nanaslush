import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
import * as schema from './schema';

dotenv.config();

// Menghapus parameter '?ssl-mode=REQUIRED' karena akan ditangani oleh objek ssl di bawah
const dbUrl = process.env.DATABASE_URL?.split('?')[0];

const poolConnection = mysql.createPool({
  uri: dbUrl,
  ssl: {
    rejectUnauthorized: false // Mengizinkan koneksi SSL Aiven tanpa harus menaruh file ca.pem di kode
  }
});

export const db = drizzle(poolConnection, { schema, mode: 'default' });