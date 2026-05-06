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

import { authenticate } from '../middleware/auth.middleware.js';
import * as chatService from '../services/chat.service.js';

router.post('/voice-query', authenticate, upload.single('audio'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No audio file provided' });
        }

        const userId = req.user.nameid;
        const { language, conversationId, activeFarmId } = req.body;
        const targetLanguage = language || 'en';

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
                // If the app is set to Sinhala, STT language should be 'si-LK'
                // For other languages or English, we default to 'en-US' or the specific language code
                // Let's adapt this based on the frontend's language choice
                languageCode: targetLanguage === 'si' ? 'si-LK' : (targetLanguage === 'ta' ? 'ta-IN' : 'en-US')
            }
        };

        const [response] = await speechClient.recognize(request);
        const sttText = response.results.map(r => r.alternatives[0].transcript).join(' ');
        
        console.log(`[VOICE] Google STT Transcript (${targetLanguage}): "${sttText}"`);

        // If STT failed to transcribe anything
        if (!sttText || sttText.trim() === '') {
            return res.status(400).json({ error: 'Could not transcribe audio' });
        }

        // 3. Instead of standalone RAG, pass directly to processMessage!
        // processMessage handles translations natively based on the 'targetLanguage' passed to it!
        // It also handles creating/updating the conversation in Firestore, extracting memory, etc.
        const result = await chatService.processMessage(
            userId,
            sttText, // The native text spoken
            conversationId,
            targetLanguage
        );

        // 4. Return answer in the new expected format
        res.json({
            success: true,
            data: {
                question: sttText,
                reply: result.reply,
                conversationId: result.conversationId,
                sources: result.sources,
                suggestions: result.suggestions
            }
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
