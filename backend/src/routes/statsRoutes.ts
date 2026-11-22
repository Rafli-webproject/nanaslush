import { Router } from 'express';
import { getAdminStats } from '../controllers/statsController';
import { verifyToken, authorizeRole } from '../middlewares/authMiddleware';

const router = Router();
router.get('/', verifyToken, authorizeRole(['admin']), getAdminStats);
export default router;