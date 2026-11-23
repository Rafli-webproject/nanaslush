import { mysqlTable, varchar, text, decimal, int, timestamp, mysqlEnum, boolean } from 'drizzle-orm/mysql-core';
import { relations } from 'drizzle-orm';

export const users = mysqlTable('users', {
  id: int('id').autoincrement().primaryKey(),
  name: varchar('name', { length: 100 }).notNull(),
  email: varchar('email', { length: 100 }).notNull().unique(),
  password: varchar('password', { length: 255 }).notNull(),
  role: mysqlEnum('role', ['admin', 'customer']).default('customer').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const products = mysqlTable('products', {
  id: int('id').autoincrement().primaryKey(),
  name: varchar('name', { length: 150 }).notNull(),
  description: text('description'),
  price: decimal('price', { precision: 10, scale: 2 }).notNull(),
  imageUrl: varchar('image_url', { length: 255 }),
  stock: int('stock').default(0).notNull(),
  createdBy: int('created_by').references(() => users.id).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const orders = mysqlTable('orders', {
  id: int('id').autoincrement().primaryKey(),
  userId: int('user_id').references(() => users.id).notNull(),
  productId: int('product_id').references(() => products.id).notNull(),
  quantity: int('quantity').notNull(),
  totalPrice: decimal('total_price', { precision: 10, scale: 2 }).notNull(),
  status: mysqlEnum('status', ['pending', 'processed', 'delivering', 'completed', 'cancelled']).default('pending').notNull(),
  
  // --- KOLOM BARU UNTUK PENGIRIMAN & PEMBAYARAN ---
  deliveryMethod: mysqlEnum('delivery_method', ['pickup', 'delivery']).default('pickup').notNull(),
  paymentMethod: mysqlEnum('payment_method', ['transfer', 'cash']).default('transfer').notNull(),
  address: text('address'), // Boleh null jika pickup
  customerPhone: varchar('customer_phone', { length: 20 }).notNull(), // Nomor HP pelanggan
  
  paymentProofUrl: varchar('payment_proof_url', { length: 255 }), // Null jika bayar cash
  notes: text('notes'),
  voucherCode: varchar('voucher_code', { length: 50 }),
  discountAmount: decimal('discount_amount', { precision: 10, scale: 2 }).default('0'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// TABEL BARU UNTUK VOUCHER
export const vouchers = mysqlTable('vouchers', {
  id: int('id').autoincrement().primaryKey(),
  code: varchar('code', { length: 50 }).notNull().unique(),
  discountPercent: int('discount_percent').notNull(), // Contoh: 10 untuk 10%
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// Relasi
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