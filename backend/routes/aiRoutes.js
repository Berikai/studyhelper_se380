import express from 'express';
import * as aiController from '../controllers/aiController.js';
import authenticateToken from '../middleware/auth.js';

const router = express.Router();

router.use(authenticateToken);

router.post('/generate-curriculum', aiController.generateCurriculum);
router.post('/generate-question', aiController.generateQuestion);
router.post('/chat', aiController.chat);

export default router;
