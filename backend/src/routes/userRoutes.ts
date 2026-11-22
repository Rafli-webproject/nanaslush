import { Router } from 'express';
import { updateProfile } from '../controllers/userController';
import { verifyToken } from '../middlewares/authMiddleware';

const router = Router();

// Hanya user yang login yang bisa mengakses ini
router.put('/profile', verifyToken, updateProfile);

export default router;