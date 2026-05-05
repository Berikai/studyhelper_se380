import sqlite3 from 'sqlite3';

const db = new sqlite3.Database('database.sqlite', (err) => {
  if (err) {
    console.error('Error opening database', err.message);
  } else {
    console.log('Connected to the SQLite database.');
    db.run(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      credits INTEGER DEFAULT 100
    )`, (err) => {
      if (err) console.error("Error creating users table", err);
    });

    db.run(`CREATE TABLE IF NOT EXISTS lectures (
      id TEXT PRIMARY KEY,
      user_id INTEGER,
      title TEXT NOT NULL,
      dateText TEXT,
      questions INTEGER DEFAULT 0,
      colorIcon TEXT,
      curriculum TEXT,
      documents TEXT DEFAULT '[]',
      flashcards TEXT DEFAULT '[]',
      content TEXT,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )`, (err) => {
      if (err) console.error("Error creating lectures table", err);
      else {
        // Migrations
        db.run(`ALTER TABLE lectures ADD COLUMN curriculum TEXT`, (err) => { });
        db.run(`ALTER TABLE lectures ADD COLUMN documents TEXT DEFAULT '[]'`, (err) => { });
        db.run(`ALTER TABLE lectures ADD COLUMN flashcards TEXT DEFAULT '[]'`, (err) => { });
        db.run(`ALTER TABLE lectures ADD COLUMN content TEXT`, (err) => { });
      }
    });

    db.run(`CREATE TABLE IF NOT EXISTS study_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      lecture_id TEXT,
      lecture_title TEXT,
      score INTEGER,
      total_questions INTEGER,
      date TEXT,
      session_data TEXT,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )`, (err) => {
      if (err) console.error("Error creating history table", err);
      else {
        db.run(`ALTER TABLE study_history ADD COLUMN session_data TEXT`, (err) => { });
      }
    });
  }
});

export default db;
