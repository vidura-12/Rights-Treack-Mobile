const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.json());

const GEMINI_API_KEY = 'AIzaSyDQSZU3zqmJn6Tu7Nbs6HrVKK43AUpoaRc'; // <-- Replace with your Gemini API key

app.post('/summarize', async (req, res) => {
  const { text } = req.body;
  try {
    const geminiResp = await axios.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      {
        contents: [{
          parts: [{
            text: `Summarize the following incident and extract these fields as JSON: case_type, place, date, contact, actions, short_summary. Text: "${text}"`
          }]
        }]
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': GEMINI_API_KEY
        }
      }
    );
    const content = geminiResp.data.candidates[0].content.parts[0].text;
    const jsonStart = content.indexOf('{');
    const jsonEnd = content.lastIndexOf('}');
    let summary = {};
    if (jsonStart !== -1 && jsonEnd !== -1) {
      summary = JSON.parse(content.substring(jsonStart, jsonEnd + 1));
    }
    res.json(summary);
  } catch (e) {
    res.status(500).json({ error: e.toString() });
  }
});

app.listen(3000, () => console.log('Summarizer running on port 3000'));