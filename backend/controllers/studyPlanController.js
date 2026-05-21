import db from '../db.js';

export const getPlans = (req, res) => {
  const { date } = req.query;
  if (date) {
    db.all(
      'SELECT * FROM study_plans WHERE user_id = ? AND target_date = ?',
      [req.user.id, date],
      (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
      }
    );
  } else {
    db.all(
      'SELECT * FROM study_plans WHERE user_id = ? ORDER BY target_date DESC',
      [req.user.id],
      (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
      }
    );
  }
};

export const getPlansByDateRange = (req, res) => {
  const { start, end } = req.query;
  if (!start || !end) return res.status(400).json({ error: 'start and end dates required' });
  db.all(
    'SELECT * FROM study_plans WHERE user_id = ? AND target_date >= ? AND target_date <= ? ORDER BY target_date ASC',
    [req.user.id, start, end],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    }
  );
};

export const createPlan = (req, res) => {
  const { lecture_id, lecture_title, target_date } = req.body;
  if (!lecture_id || !target_date) return res.status(400).json({ error: 'lecture_id and target_date required' });

  db.run(
    'INSERT INTO study_plans (user_id, lecture_id, lecture_title, target_date) VALUES (?, ?, ?, ?)',
    [req.user.id, lecture_id, lecture_title || 'Untitled', target_date],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json({
        id: this.lastID,
        user_id: req.user.id,
        lecture_id,
        lecture_title: lecture_title || 'Untitled',
        target_date,
        completed: 0
      });
    }
  );
};

export const togglePlan = (req, res) => {
  db.get(
    'SELECT * FROM study_plans WHERE id = ? AND user_id = ?',
    [req.params.id, req.user.id],
    (err, row) => {
      if (err || !row) return res.status(404).json({ error: 'Plan not found' });
      const newCompleted = row.completed ? 0 : 1;
      db.run(
        'UPDATE study_plans SET completed = ? WHERE id = ? AND user_id = ?',
        [newCompleted, req.params.id, req.user.id],
        function (err) {
          if (err) return res.status(500).json({ error: err.message });
          res.json({ ...row, completed: newCompleted });
        }
      );
    }
  );
};

export const deletePlan = (req, res) => {
  db.run(
    'DELETE FROM study_plans WHERE id = ? AND user_id = ?',
    [req.params.id, req.user.id],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
    }
  );
};
