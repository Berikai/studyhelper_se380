import 'dotenv/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import db from '../db.js';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || 'MOCK_KEY');

export const generateCurriculum = async (req, res) => {
  try {
    const { lectureId, lectureTitle } = req.body;
    if (!lectureTitle || !lectureId) return res.status(400).json({ error: 'Lecture ID and title required' });

    // Check if curriculum exists in DB
    db.get('SELECT curriculum FROM lectures WHERE id = ? AND user_id = ?', [lectureId, req.user.id], async (err, row) => {
      if (err) return res.status(500).json({ error: err.message });
      if (row && row.curriculum) {
        try {
          return res.json({ curriculum: JSON.parse(row.curriculum) });
        } catch (e) {
          // Fall through to regenerate
        }
      }

      // Check if real key is provided
      if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'MOCK_KEY') {
        const mockCurriculum = [
          { topic: `Introduction to ${lectureTitle}`, duration: '1 hour' },
          { topic: `Advanced concepts in ${lectureTitle}`, duration: '2 hours' },
          { topic: `Practical applications of ${lectureTitle}`, duration: '1.5 hours' }
        ];
        db.run('UPDATE lectures SET curriculum = ? WHERE id = ?', [JSON.stringify(mockCurriculum), lectureId]);
        return res.json({ curriculum: mockCurriculum });
      }

      const model = genAI.getGenerativeModel({ model: 'gemini-flash-latest' });
      const prompt = `Generate a concise study curriculum for a lecture titled "${lectureTitle}". Return a JSON array of objects with 'topic' and 'duration' keys. Respond only with the JSON.`;

      try {
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        let curriculumData;
        const jsonMatch = text.match(/\[.*\]/s);
        if (jsonMatch) {
          curriculumData = JSON.parse(jsonMatch[0]);
        } else {
          curriculumData = JSON.parse(text);
        }

        db.run('UPDATE lectures SET curriculum = ? WHERE id = ?', [JSON.stringify(curriculumData), lectureId]);
        res.json({ curriculum: curriculumData });
      } catch (e) {
        res.status(500).json({ error: "Failed to generate curriculum" });
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const generateQuestion = async (req, res) => {
  const { lectureId } = req.body;

  // Check credits first
  db.get('SELECT credits FROM users WHERE id = ?', [req.user.id], async (err, user) => {
    if (err || !user) return res.status(500).json({ error: "User not found" });
    if (user.credits < 1) return res.status(403).json({ error: "Insufficient credits. Please top up." });

    // Get lecture content
    db.get('SELECT * FROM lectures WHERE id = ? AND user_id = ?', [lectureId, req.user.id], async (err, lecture) => {
      if (err || !lecture) return res.status(404).json({ error: "Lecture not found" });

      // Mock fallback
      if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY.includes('MOCK')) {
        const mockQuestion = {
          question: `Based on "${lecture.title}", which concept is most critical?`,
          options: ["Concept Analysis", "Practical Application", "Theoretical Framework", "None of the above"],
          correctIndex: 0,
          explanation: "This is a mock question generated because no API key is present."
        };
        db.run('UPDATE users SET credits = credits - 1 WHERE id = ?', [req.user.id]);
        return res.json(mockQuestion);
      }

      // Deduct credit
      db.run('UPDATE users SET credits = credits - 1 WHERE id = ?', [req.user.id]);

      try {
        const model = genAI.getGenerativeModel({ model: "gemini-flash-latest" });

        const context = `Lecture Title: ${lecture.title}\nContent: ${lecture.content || 'N/A'}\nDocuments: ${lecture.documents || '[]'}`;

        const prompt = `Generate a high-quality, multiple-choice study question based on the following lecture context. 
                If the content is provided, use it to create specific questions. If content is sparse, use the title to generate relevant academic questions.
                
                CONTEXT:
                ${context}
                
                The question should be academic and test deep understanding.
                
                IMPORTANT: 
                - Do NOT wrap the entire question or options in dollar signs ($). 
                - Use dollar signs ONLY for specific mathematical formulas or symbols (e.g., $E=mc^2$).
                - Ensure regular text is NOT inside dollar signs, as it will break formatting and remove spaces.
                
                Respond ONLY with a JSON object in the following format:
                {
                  "question": "The question text",
                  "options": ["Option A", "Option B", "Option C", "Option D"],
                  "correctIndex": 0,
                  "explanation": "Brief explanation of why the answer is correct"
                }`;

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        let questionData;
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          questionData = JSON.parse(jsonMatch[0]);
        } else {
          questionData = JSON.parse(text);
        }

        // Track usage
        db.run('UPDATE lectures SET questions = questions + 1 WHERE id = ?', [lectureId]);

        res.json(questionData);
      } catch (error) {
        console.error("AI Error:", error);
        // Refund credit on failure
        db.run('UPDATE users SET credits = credits + 1 WHERE id = ?', [req.user.id]);
        res.status(500).json({ error: "AI failed to generate question. Please try again." });
      }
    });
  });
};

export const chat = async (req, res) => {
  try {
    const { message, context } = req.body;
    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'MOCK_KEY') {
      return res.json({ response: `This is a mock response to: "${message}". Set GEMINI_API_KEY to use real AI.` });
    }

    const model = genAI.getGenerativeModel({ model: 'gemini-flash-latest' });
    const prompt = `Context: ${context}\n\nStudent asks: ${message}\n\nProvide a helpful, concise answer:`;
    const result = await model.generateContent(prompt);
    res.json({ response: result.response.text() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
