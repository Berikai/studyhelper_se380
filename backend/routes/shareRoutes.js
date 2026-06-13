import express from 'express';
import * as shareController from '../controllers/shareController.js';
import authenticateToken from '../middleware/auth.js';

const router = express.Router();

// All share routes require authentication
router.use(authenticateToken);

router.post('/', shareController.shareFlashcards);
router.get('/users', shareController.getSharedUsers);
router.get('/users/:sender_id/lectures', shareController.getSharedLectures);

export default router;
