import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export const verifyToken = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ success: false, message: 'Akses ditolak, token tidak ditemukan' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as { id: number; role: 'admin' | 'customer' };
    req.user = decoded; // Menyimpan data user ke request
    next();
  } catch (error) {
    res.status(401).json({ success: false, message: 'Token tidak valid atau kedaluwarsa' });
  }
};

export const authorizeRole = (roles: ('admin' | 'customer')[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user || !roles.includes(req.user.role)) {
      res.status(403).json({ success: false, message: 'Akses ditolak, Anda tidak memiliki izin' });
      return;
    }
    next();
  };
};