import express from 'express';
import * as lectureController from '../controllers/lectureController.js';
import authenticateToken from '../middleware/auth.js';

const router = express.Router();

router.use(authenticateToken);

router.get('/', lectureController.getAllLectures);
router.post('/', lectureController.createLecture);
router.post('/seed', lectureController.seedLectures);
router.put('/:id', lectureController.updateLecture);
router.delete('/:id', lectureController.deleteLecture);
router.post('/:id/documents', lectureController.addDocument);
router.delete('/:id/documents/:index', lectureController.deleteDocument);
router.post('/:id/flashcards', lectureController.addFlashcard);

export default router;
