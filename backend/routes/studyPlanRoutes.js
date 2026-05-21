import express from 'express';
import * as planController from '../controllers/studyPlanController.js';
import authenticateToken from '../middleware/auth.js';

const router = express.Router();
router.use(authenticateToken);

router.get('/', planController.getPlans);
router.get('/range', planController.getPlansByDateRange);
router.post('/', planController.createPlan);
router.put('/:id', planController.togglePlan);
router.delete('/:id', planController.deletePlan);

export default router;
