import 'dotenv/config'; // Import env file to access environment variables
import db from '../db.js';

export const getAllLectures = (req, res) => {
  db.all('SELECT * FROM lectures WHERE user_id = ?', [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
};

export const createLecture = (req, res) => {
  const newLecture = {
    id: Date.now().toString(),
    user_id: req.user.id,
    title: req.body.title || "Untitled Lecture",
    dateText: "Created Just Now",
    questions: 0,
    colorIcon: req.body.colorIcon || "blue",
    documents: req.body.documents || '[]',
    flashcards: req.body.flashcards || '[]',
    content: req.body.content || ""
  };

  db.run('INSERT INTO lectures (id, user_id, title, dateText, questions, colorIcon, documents, flashcards, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [newLecture.id, newLecture.user_id, newLecture.title, newLecture.dateText, newLecture.questions, newLecture.colorIcon, newLecture.documents, newLecture.flashcards, newLecture.content], (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json(newLecture);
    });
};

export const seedLectures = (req, res) => {
  const mockLectures = [
    { id: Date.now().toString() + '1', title: "Biology 101: Cell Stru...", dateText: "Created Oct 12, 2023", questions: 15, colorIcon: "blue" },
    { id: Date.now().toString() + '2', title: "Calculus: Derivatives", dateText: "Created Oct 10, 2023", questions: 22, colorIcon: "green" },
    { id: Date.now().toString() + '3', title: "World History: WWII", dateText: "Created Sep 28, 2023", questions: 0, colorIcon: "orange" },
    { id: Date.now().toString() + '4', title: "Intro to Python", dateText: "Created Sep 15, 2023", questions: 40, colorIcon: "pink" }
  ];

  const stmt = db.prepare('INSERT INTO lectures (id, user_id, title, dateText, questions, colorIcon) VALUES (?, ?, ?, ?, ?, ?)');
  mockLectures.forEach(l => stmt.run(l.id, req.user.id, l.title, l.dateText, l.questions, l.colorIcon));
  stmt.finalize();

  res.json({ message: 'Seeded lectures successfully', lectures: mockLectures });
};

export const updateLecture = (req, res) => {
  const { title, content } = req.body;
  db.run('UPDATE lectures SET title = ?, content = ? WHERE id = ? AND user_id = ?',
    [title, content, req.params.id, req.user.id], function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
    });
};

export const deleteLecture = (req, res) => {
  db.run('DELETE FROM lectures WHERE id = ? AND user_id = ?', [req.params.id, req.user.id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
};

export const addDocument = (req, res) => {
  const { documentName } = req.body;
  db.get('SELECT documents FROM lectures WHERE id = ? AND user_id = ?', [req.params.id, req.user.id], (err, row) => {
    if (err || !row) return res.status(404).json({ error: "Lecture not found" });
    let docs = [];
    try { docs = JSON.parse(row.documents); } catch (e) { }
    docs.push(documentName);
    db.run('UPDATE lectures SET documents = ? WHERE id = ?', [JSON.stringify(docs), req.params.id], (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ documents: docs });
    });
  });
};

export const deleteDocument = (req, res) => {
  db.get('SELECT documents FROM lectures WHERE id = ? AND user_id = ?', [req.params.id, req.user.id], (err, row) => {
    if (err || !row) return res.status(404).json({ error: "Lecture not found" });
    let docs = [];
    try { docs = JSON.parse(row.documents); } catch (e) { }
    docs.splice(parseInt(req.params.index), 1);
    db.run('UPDATE lectures SET documents = ? WHERE id = ?', [JSON.stringify(docs), req.params.id], (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ documents: docs });
    });
  });
};

export const addFlashcard = (req, res) => {
  const { question, answer } = req.body;
  db.get('SELECT flashcards, questions FROM lectures WHERE id = ? AND user_id = ?', [req.params.id, req.user.id], (err, row) => {
    if (err || !row) return res.status(404).json({ error: "Lecture not found" });
    let cards = [];
    try { cards = JSON.parse(row.flashcards); } catch (e) { }
    cards.push({ question, answer });
    db.run('UPDATE lectures SET flashcards = ?, questions = ? WHERE id = ?', [JSON.stringify(cards), (row.questions || 0) + 1, req.params.id], (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ flashcards: cards });
    });
  });
};
