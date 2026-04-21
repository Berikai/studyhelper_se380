/**
 * StudyHelper Backend Server
 * 
 * This Express.js server provides a simple API for managing lectures, flashcards, quizzes, and Gemini AI interactions for the StudyHelper app.
 */
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 9090;

app.use(cors());
app.use(express.json());

// In-Memory Mock Data repository for Lectures (replaces Flutter client state later)
let lectures = [
  { id: '1', title: "Biology 101: Cell Stru...", dateText: "Created Oct 12, 2023", questions: 15, colorIcon: "blue" },
  { id: '2', title: "Calculus: Derivatives", dateText: "Created Oct 10, 2023", questions: 22, colorIcon: "green" },
  { id: '3', title: "World History: WWII", dateText: "Created Sep 28, 2023", questions: 0, colorIcon: "orange" },
  { id: '4', title: "Intro to Python", dateText: "Created Sep 15, 2023", questions: 40, colorIcon: "pink" }
];

// --- ROUTES --- //

// Health check route
app.get('/api/status', (req, res) => {
  res.json({ status: 'OK', message: 'StudyHelper API is up and running!' });
});

// Fetch all lectures
app.get('/api/lectures', (req, res) => {
  res.json(lectures);
});

// Create a new lecture
app.post('/api/lectures', (req, res) => {
  const newLecture = {
    id: Date.now().toString(),
    title: req.body.title || "Untitled Lecture",
    dateText: "Created Just Now",
    questions: 0,  // Defaults to 0 since processing isn't built yet
    colorIcon: req.body.colorIcon || "blue"
  };

  lectures.push(newLecture);
  res.status(201).json(newLecture);
});

// Note: Future routes for Flashcards, Quizzes, and Gemini AI will go here.

// Initialize Server
app.listen(PORT, () => {
  console.log(`StudyHelper backend server is running on http://localhost:${PORT}`);
});
