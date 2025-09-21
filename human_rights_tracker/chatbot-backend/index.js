const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Gemini API Key
const GEMINI_API_KEY = 'AIzaSyARlAD651ACiA38qgjdMS-4ZU7W1nqJ4aY';

app.post('/chat', async (req, res) => {
  const userText = req.body.message;

  try {
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        contents: [
          { role: "user", parts: [{ text: userText }] }
        ]
      }
    );

    const aiReply = response.data?.candidates?.[0]?.content?.parts?.[0]?.text || "No reply from Gemini.";
    res.json({ reply: aiReply });

  } catch (error) {
    console.error(error.response ? error.response.data : error.message);
    res.status(500).json({ error: error.response?.data || error.message });
  }
});

app.listen(5000, () => {
  console.log("Chatbot backend running on port 5000");
});
