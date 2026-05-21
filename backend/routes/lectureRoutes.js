import express from 'express';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import * as lectureController from '../controllers/lectureController.js';
import authenticateToken from '../middleware/auth.js';

const uploadDir = 'uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const unique = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, unique + path.extname(file.originalname));
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['application/pdf', 'text/plain', 'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only PDF, TXT, DOC, and DOCX files are allowed'));
    }
  }
});

const router = express.Router();

router.use(authenticateToken);

router.get('/', lectureController.getAllLectures);
router.post('/', (req, res, next) => {
  upload.single('document')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ error: 'File too large. Maximum size is 10MB.' });
      }
      return res.status(400).json({ error: err.message });
    }
    next();
  });
}, lectureController.createLecture);
router.post('/seed', lectureController.seedLectures);
router.put('/:id', lectureController.updateLecture);
router.delete('/:id', lectureController.deleteLecture);
router.post('/:id/documents', (req, res, next) => {
  upload.single('document')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ error: 'File too large. Maximum size is 10MB.' });
      }
      return res.status(400).json({ error: err.message });
    }
    next();
  });
}, lectureController.addDocument);
router.delete('/:id/documents/:index', lectureController.deleteDocument);
router.post('/:id/flashcards', lectureController.addFlashcard);

export default router;
