# AI Clue Server

A simple Node.js server that generates creative animal clues using OpenAI's ChatGPT API for the WildGuess Flutter app.

## Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment:**
   ```bash
   cp env.example .env
   ```
   Then edit `.env` and add your OpenAI API key.

3. **Run the server:**
   ```bash
   # Development mode (with auto-restart)
   npm run dev
   
   # Production mode
   npm start
   ```

## API Endpoints

### Health Check
```bash
curl http://localhost:3000/health
```

### Generate Animal Clues
```bash
curl -X POST http://localhost:3000/clues \
  -H "Content-Type: application/json" \
  -d '{
    "animalName": "Rådjur",
    "scientificName": "Capreolus capreolus",
    "description": "A small deer species",
    "isEnglish": false
  }'
```

### Generic Chat
```bash
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello!"}
    ]
  }'
```