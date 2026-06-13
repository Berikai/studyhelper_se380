import db from '../db.js';

export const shareFlashcards = (req, res) => {
  const { email, lectureId } = req.body;
  const senderId = req.user.id;

  if (!email || !lectureId) {
    return res.status(400).json({ error: 'Email and lectureId required' });
  }

  // Find the receiver user with her/his email
  db.get('SELECT id FROM users WHERE email = ?', [email], (err, receiver) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!receiver) return res.status(404).json({ error: 'user not found' });

    if (receiver.id === senderId) {
      return res.status(400).json({ error: 'Cannot share flashcards with yourself' });
    }

    // Get the lecture to get the flashcards snapshot from database
    db.get('SELECT title, flashcards FROM lectures WHERE id = ? AND user_id = ?', [lectureId, senderId], (err, lecture) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!lecture) return res.status(404).json({ error: 'Lecture not found' });

      // Insert into shared_flashcards
      db.run(
        'INSERT INTO shared_flashcards (sender_id, receiver_id, lecture_id, lecture_title, flashcards) VALUES (?, ?, ?, ?, ?)',
        [senderId, receiver.id, lectureId, lecture.title, lecture.flashcards],
        function (err) {
          if (err) {
            if (err.message.includes('UNIQUE')) {
              return res.status(400).json({ error: 'already shared' });
            }
            return res.status(500).json({ error: err.message });
          }
          res.status(201).json({ message: 'Shared successfully', id: this.lastID });
        }
      );
    });
  });
};

export const getSharedUsers = (req, res) => {
  const receiverId = req.user.id;

  // Return distinct users who shared at least one flashcard set with this user
  const query = `
    SELECT DISTINCT u.id, u.email 
    FROM shared_flashcards s
    JOIN users u ON s.sender_id = u.id
    WHERE s.receiver_id = ?
  `;

  db.all(query, [receiverId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
};

export const getSharedLectures = (req, res) => {
  const receiverId = req.user.id;
  const senderId = req.params.sender_id;

  const query = `
    SELECT lecture_id, lecture_title, flashcards, shared_at
    FROM shared_flashcards
    WHERE receiver_id = ? AND sender_id = ?
  `;

  db.all(query, [receiverId, senderId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
};
