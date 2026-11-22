import { Router } from 'express';
import multer from 'multer';
import { createProduct, getAllProducts, getProductById, updateProduct, deleteProduct } from '../controllers/productController';
import { verifyToken, authorizeRole } from '../middlewares/authMiddleware';

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

// Rute Public (Bisa diakses Customer & Admin)
router.get('/', getAllProducts);
router.get('/:id', getProductById);

// Rute Private (Hanya Admin)
router.post('/', verifyToken, authorizeRole(['admin']), upload.single('image'), createProduct);
router.put('/:id', verifyToken, authorizeRole(['admin']), upload.single('image'), updateProduct);
router.delete('/:id', verifyToken, authorizeRole(['admin']), deleteProduct);

export default router;