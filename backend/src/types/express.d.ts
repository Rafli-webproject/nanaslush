import { users } from '../db/schema';

declare global {
  namespace Express {
    interface Request {
      user?: {
        id: number;
        role: 'admin' | 'customer';
      };
    }
  }
}