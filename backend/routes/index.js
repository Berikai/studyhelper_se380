import express from 'express';

import authRoutes from './authRoutes.js';
import lectureRoutes from './lectureRoutes.js';
import aiRoutes from './aiRoutes.js';
import historyRoutes from './historyRoutes.js';
import studyPlanRoutes from './studyPlanRoutes.js';

const router = express.Router();

// backend routes
router.use('/auth', authRoutes);
router.use('/lectures', lectureRoutes);
router.use('/ai', aiRoutes);
router.use('/history', historyRoutes);
router.use('/plans', studyPlanRoutes);

export default router;
