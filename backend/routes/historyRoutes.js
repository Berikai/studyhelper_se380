import express from 'express';
import * as historyController from '../controllers/historyController.js';
import authenticateToken from '../middleware/auth.js';

const router = express.Router();

router.use(authenticateToken);

router.get('/', historyController.getHistory);
router.post('/', historyController.createHistory);

export default router;
