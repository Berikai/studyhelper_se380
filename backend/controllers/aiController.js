import 'dotenv/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { GoogleAIFileManager } from '@google/generative-ai/server';
import fs from 'fs';
import db from '../db.js';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || 'MOCK_KEY');
const fileManager = new GoogleAIFileManager(process.env.GEMINI_API_KEY || 'MOCK_KEY');

async function uploadDocumentToGemini(filePath, mimeType, displayName) {
  try {
    const result = await fileManager.uploadFile(filePath, {
      mimeType,
      displayName
    });
    return result.file;
  } catch (e) {
    console.error('Gemini file upload error:', e.message);
    return null;
  }
}

async function buildGeminiParts(lecture, basePrompt) {
  const parts = [{ text: basePrompt }];

  let docs = [];
  try { docs = JSON.parse(lecture.documents || '[]'); } catch (e) { }

  for (const doc of docs) {
    const filePath = doc.path || doc;
    const mime = doc.mime || 'application/octet-stream';
    const name = doc.name || 'document';

    if (fs.existsSync(filePath)) {
      if (mime === 'text/plain') {
        try {
          const content = fs.readFileSync(filePath, 'utf-8');
          parts.push({ text: `\n\n--- Document Content (${name}) ---\n${content}\n--- End Document ---` });
        } catch (e) {
          console.error('Error reading text file:', e.message);
        }
      } else {
        const geminiFile = await uploadDocumentToGemini(filePath, mime, name);
        if (geminiFile) {
          parts.push({
            fileData: {
              mimeType: geminiFile.mimeType,
              fileUri: geminiFile.uri
            }
          });
        }
      }
    }
  }

  return parts;
}

export const generateCurriculum = async (req, res) => {
  try {
    const { lectureId, lectureTitle, force } = req.body;
    if (!lectureTitle || !lectureId) return res.status(400).json({ error: 'Lecture ID and title required' });

    db.get('SELECT * FROM lectures WHERE id = ? AND user_id = ?', [lectureId, req.user.id], async (err, lecture) => {
      if (err || !lecture) return res.status(404).json({ error: "Lecture not found" });

      // Return cached curriculum if it exists and not forced
      if (lecture.curriculum && !force) {
        try {
          return res.json({ curriculum: JSON.parse(lecture.curriculum) });
        } catch (e) { /* Fall through to regenerate */ }
      }

      // Mock fallback
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
      const prompt = `Generate a concise study curriculum for a lecture titled "${lectureTitle}".${lecture.content ? ` Content: ${lecture.content}` : ''} Return a JSON array of objects with 'topic' and 'duration' keys. Respond only with the JSON.`;

      try {
        const parts = await buildGeminiParts(lecture, prompt);
        const result = await model.generateContent(parts);
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

        const contextText = `Lecture Title: ${lecture.title}\nContent: ${lecture.content || 'N/A'}`;

        const prompt = `Generate a high-quality, multiple-choice study question based on the following lecture context. 
                If the content or attached documents are provided, use them to create specific questions. If content is sparse, use the title to generate relevant academic questions.
                
                CONTEXT:
                ${contextText}
                
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

        const parts = await buildGeminiParts(lecture, prompt);
        const result = await model.generateContent(parts);
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
