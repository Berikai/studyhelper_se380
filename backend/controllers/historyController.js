import db from '../db.js';

export const getHistory = (req, res) => {
  db.all('SELECT * FROM study_history WHERE user_id = ? ORDER BY id DESC', [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
};

export const createHistory = (req, res) => {
  const { lecture_id, lecture_title, score, total_questions, session_data } = req.body;
  const dateText = new Date().toLocaleDateString();

  db.run('INSERT INTO study_history (user_id, lecture_id, lecture_title, score, total_questions, date, session_data) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [req.user.id, lecture_id, lecture_title, score, total_questions, dateText, session_data], function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID, lecture_id, score, total_questions, date: dateText });
    });
};
