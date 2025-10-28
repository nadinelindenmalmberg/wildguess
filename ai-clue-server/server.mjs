import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import OpenAI from 'openai';
// import rateLimit from 'express-rate-limit'; // optional: use a lib limiter
// import { z } from 'zod'; // optional: schema validation

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Trust proxy so req.ip works behind Vercel/Render/NGINX
app.set('trust proxy', 1);

// CORS: during dev allow all; in prod, pin your domain
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || true,
  methods: ['POST', 'GET'],
}));
app.use(express.json());

// Tiny in-memory caches (OK for prototype)
const clueCache = new Map();
const RATE_LIMIT = new Map();
const RATE_LIMIT_WINDOW = 60_000; // 1 min
const RATE_LIMIT_MAX_REQUESTS = 10;

// Simple IP rate limiter
app.use((req, res, next) => {
  const clientIP = (req.headers['x-forwarded-for']?.toString().split(',')[0] || req.ip || 'unknown').trim();
  const now = Date.now();
  const arr = (RATE_LIMIT.get(clientIP) || []).filter(t => now - t < RATE_LIMIT_WINDOW);
  if (arr.length >= RATE_LIMIT_MAX_REQUESTS) return res.status(429).json({ error: 'Rate limit exceeded' });
  arr.push(now); RATE_LIMIT.set(clientIP, arr);
  next();
});

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

app.get('/health', (_req, res) => res.json({ status: 'OK' }));

// Generic chat passthrough (keep, but still prefer /clues for app)
app.post('/chat', async (req, res) => {
  try {
    const { messages } = req.body;
    if (!Array.isArray(messages)) return res.status(400).json({ error: 'messages[] required' });

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // modern, low-cost
      temperature: 0.7,
      messages,
    });
    const text = completion.choices[0]?.message?.content ?? '';
    res.json({ text });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'OpenAI call failed' });
  }
});

// Deterministic clue endpoint
app.post('/clues', async (req, res) => {
  try {
    const { animalName, scientificName, description, isEnglish = false } = req.body || {};
    if (!animalName || typeof animalName !== 'string') return res.status(400).json({ error: 'animalName required' });

    const language = isEnglish ? 'English' : 'Swedish';
    const cacheKey = `${animalName}::${scientificName || ''}::${language}`;
    if (clueCache.has(cacheKey)) return res.json({ clues: clueCache.get(cacheKey) });

    const system = [
      'You write 5 clues for a Swedish wildlife guessing game.',
      'Rules:',
      '- Output STRICT JSON matching this schema: {"clues": ["string", "string", "string", "string", "string"]}',
      '- Clues 1→5 go from hardest to easiest',
      `- Language: ${language}`,
      '- NEVER reveal the animal name directly in any clue',
      '- NEVER say "it is called", "its name is", "in Swedish it is", etc.',
      '- NEVER mention the Swedish name, common name, or scientific name',
      '- Focus on physical characteristics, habitat, behavior, diet, size, etc.',
      '- Clue 5 can be more specific but still avoid the exact name',
      '- Make clues educational and interesting about the animal',
    ].join('\n');

    const user = `
Create 5 clues for this animal (do NOT mention its name):
- Swedish Name: ${animalName}
- Scientific Name: ${scientificName || 'Unknown'}
- Description: ${description || 'No description'}

Write clues about its appearance, habitat, behavior, diet, size, etc.
Make them educational and progressively easier.

Good examples:
- "This animal has a thick winter coat"
- "It lives in forests and hunts at night"
- "It has sharp claws and excellent hearing"

Bad examples (NEVER do this):
- "In Swedish it's called iller"
- "Its name is..."
- "It is known as..."

Return ONLY a JSON array of 5 strings.
`.trim();

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      temperature: 0.5,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ],
      max_tokens: 400,
    });

    // parse the JSON text into an object
    const json = JSON.parse(completion.choices[0].message.content);
    const clues = json.clues;

    // cache + return
    clueCache.set(cacheKey, clues);
    setTimeout(() => clueCache.delete(cacheKey), 3_600_000);

    res.json({ clues });
  } catch (err) {
    console.error('clues error', err);
    res.status(500).json({ error: 'Failed to generate clues' });
  }
});

app.post('/facts', async (req, res) => {
  try {
    const { animalName, scientificName, description, isEnglish = false } = req.body || {};
    if (!animalName || typeof animalName !== 'string') return res.status(400).json({ error: 'animalName required' });

    const language = isEnglish ? 'English' : 'Swedish';
    // Lägg till caching här om önskvärt, liknande /clues

    const system = [
      'You generate 3-5 interesting and verifiable facts about a specific animal for a wildlife guessing game result screen.',
      'Rules:',
      '- Output STRICT JSON matching this schema: {"facts": ["string", "string", "string", ...]}',
      `- Language: ${language}`,
      '- Facts should be interesting, concise, and educational.',
      '- You CAN and SHOULD mention the animal\'s name.',
      '- Focus on unique characteristics, behavior, habitat, conservation status, or surprising details.',
      '- Avoid generic statements.',
    ].join('\n');

    const user = `
Generate 3-5 interesting facts about this animal:
- Name: ${animalName}
- Scientific Name: ${scientificName || 'Unknown'}
- Description: ${description || 'No description'}

Return ONLY a JSON array of 3-5 strings.
`.trim();

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // Eller annan modell
      temperature: 0.6,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ],
      max_tokens: 300,
    });

    const json = JSON.parse(completion.choices[0].message.content);
    const facts = json.facts;

    // Spara i cache om implementerat
    res.json({ facts });
  } catch (err) {
    console.error('facts error', err);
    res.status(500).json({ error: 'Failed to generate facts' });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on http://localhost:${port}`);
  console.log('Available endpoints:');
  console.log('  GET  /health - Health check');
  console.log('  POST /chat   - Generic chat endpoint');
  console.log('  POST /clues  - Animal clue generation');
  console.log(' POST /facts - Animal fact generation');
});
