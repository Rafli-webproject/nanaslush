import { Router } from 'express';
import multer from 'multer';
import { createOrder, getOrders, updateOrderStatus } from '../controllers/orderController';
import { verifyToken, authorizeRole } from '../middlewares/authMiddleware';

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

// Semua route pesanan wajib login (verifyToken)
router.use(verifyToken);

// Customer membuat pesanan (dengan upload bukti)
router.post('/', authorizeRole(['customer']), upload.single('paymentProof'), createOrder);

// Admin & Customer melihat daftar pesanan
router.get('/', authorizeRole(['admin', 'customer']), getOrders);

// Admin mengubah status pesanan
router.put('/:id/status', authorizeRole(['admin']), updateOrderStatus);

export default router;