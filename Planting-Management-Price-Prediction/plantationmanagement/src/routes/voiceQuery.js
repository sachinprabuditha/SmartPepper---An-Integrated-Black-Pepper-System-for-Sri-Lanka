import express from 'express';
import multer from 'multer';
import fs from 'fs';
import OpenAI from 'openai';
import { askPepperRAG } from '../services/rag.service.js';
import { SpeechClient } from '@google-cloud/speech';
import { v2 } from '@google-cloud/translate';

const router = express.Router();
const speechClient = new SpeechClient();
const translate = new v2.Translate();

import path from 'path';

const storage = multer.diskStorage({
    destination: 'uploads/',
    filename: (req, file, cb) => {
        // Fallback to .m4a if no extension is found
        const ext = path.extname(file.originalname) || '.m4a';
        cb(null, file.fieldname + '-' + Date.now() + ext);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY
});

router.post('/voice-query', upload.single('audio'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No audio file provided' });
        }

        // 1. Read audio as base64
        const audioBytes = fs.readFileSync(req.file.path).toString('base64');

        // 2. Call Google Cloud STT
        const request = {
            audio: {
                content: audioBytes
            },
            config: {
                encoding: 'MP3',
                sampleRateHertz: 16000,
                languageCode: 'si-LK'
            }
        };

        const [response] = await speechClient.recognize(request);
        const sinhalaText = response.results.map(r => r.alternatives[0].transcript).join(' ');
        
        console.log(`[VOICE] Google STT Sinhala Transcript: "${sinhalaText}"`);

        // 3. Call Google Cloud Translate
        const [englishText] = await translate.translate(sinhalaText, 'en');
        console.log(`[VOICE] Translated to English: "${englishText}"`);

        // 4. RAG query
        const ragResult = await askPepperRAG({ question: englishText });
        const englishAnswer = ragResult.reply;

        // 5. Translate answer back to Sinhala using OpenAI
        const completion = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
                { role: "system", content: "You are an expert translator. Translate the following English agricultural advice into natural Sri Lankan Sinhala." },
                { role: "user", content: englishAnswer }
            ]
        });
        const sinhalaAnswer = completion.choices[0].message.content;

        // 6. Return answer
        res.json({
            sinhala_question: sinhalaText,
            english_question: englishText,
            english_answer: englishAnswer,
            sinhala_answer: sinhalaAnswer
        });

    } catch (error) {
        console.error('Voice processing failed:', error);
        res.status(500).json({ error: 'Voice processing failed' });
    } finally {
        if (req.file && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
        }
    }
});

export default router;
