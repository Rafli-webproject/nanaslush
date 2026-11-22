import { mysqlTable, varchar, text, decimal, int, timestamp, mysqlEnum } from 'drizzle-orm/mysql-core';
import { relations } from 'drizzle-orm';

// 1. Tabel Users (Admin & Customer)
export const users = mysqlTable('users', {
  id: int('id').autoincrement().primaryKey(),
  name: varchar('name', { length: 100 }).notNull(),
  email: varchar('email', { length: 100 }).notNull().unique(),
  password: varchar('password', { length: 255 }).notNull(), // Akan di-hash
  role: mysqlEnum('role', ['admin', 'customer']).default('customer').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// 2. Tabel Products (Minuman)
export const products = mysqlTable('products', {
  id: int('id').autoincrement().primaryKey(),
  name: varchar('name', { length: 150 }).notNull(),
  description: text('description'),
  price: decimal('price', { precision: 10, scale: 2 }).notNull(),
  imageUrl: varchar('image_url', { length: 255 }), // Menyimpan URL dari Cloudinary
  stock: int('stock').default(0).notNull(),
  createdBy: int('created_by').references(() => users.id).notNull(), // Foreign Key ke Admin
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// 3. Tabel Orders (Pesanan)
export const orders = mysqlTable('orders', {
  id: int('id').autoincrement().primaryKey(),
  userId: int('user_id').references(() => users.id).notNull(), // Foreign Key ke Customer
  productId: int('product_id').references(() => products.id).notNull(), // Foreign Key ke Produk
  quantity: int('quantity').notNull(),
  totalPrice: decimal('total_price', { precision: 10, scale: 2 }).notNull(),
  status: mysqlEnum('status', ['pending', 'processed', 'completed', 'cancelled']).default('pending').notNull(),
  paymentProofUrl: varchar('payment_proof_url', { length: 255 }), // URL Cloudinary
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// Definisi Relasi (Untuk memudahkan Query)
export const usersRelations = relations(users, ({ many }) => ({
  products: many(products),
  orders: many(orders),
}));

export const productsRelations = relations(products, ({ one, many }) => ({
  author: one(users, { fields: [products.createdBy], references: [users.id] }),
  orders: many(orders),
}));

export const ordersRelations = relations(orders, ({ one }) => ({
  customer: one(users, { fields: [orders.userId], references: [users.id] }),
  product: one(products, { fields: [orders.productId], references: [products.id] }),
}));