// src/services/chat.service.js

import { askPepperRAG } from './rag.service.js';
import * as chatRepo from '../repositories/chat.repository.js';
import { summarizeConversation } from './memory.service.js';

import { extractMemory } from './memory.extractor.js';
import { saveMemory } from '../repositories/memory.vector.repository.js';
import { searchRelevantMemories } from './memory.search.service.js';

import { v2 } from '@google-cloud/translate';
import OpenAI from 'openai';

const translate = new v2.Translate();
const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY
});

/**
 * Generate conversation title
 */
const generateTitle = (message) => {

    if (!message) return "New Chat";

    let title = message.trim();

    const lowValueMessages = [
        "hi", "hello", "thanks", "ok", "okay", "yes", "no"
    ];

    if (lowValueMessages.includes(title.toLowerCase())) {
        return "Pepper Farming Advice";
    }

    if (title.length > 60) {
        title = title.substring(0, 57) + "...";
    }

    title = title.replace(/[?!.]+$/, '');

    title =
        title.charAt(0).toUpperCase() +
        title.slice(1);

    return title;
};


/**
 * =============================
 * MAIN CHAT PROCESSOR
 * =============================
 */
export const processMessage = async (
    userId,
    message,
    conversationId,
    language = 'en'
) => {
    let processMessageContent = message;

    // =============================
    // ⭐ Translation (To English)
    // =============================
    if (language !== 'en') {
        try {
            const [englishText] = await translate.translate(message, 'en');
            processMessageContent = englishText;
            console.log(`[CHAT] Translated to English: "${processMessageContent}"`);
        } catch (err) {
            console.error("Translation to English failed:", err);
        }
    }

    // =============================
    // 1️⃣ Create conversation
    // =============================
    if (!conversationId || conversationId.trim() === "") {
        conversationId =
            await chatRepo.createConversation(userId);
    }

    // =============================
    // 2️⃣ Save user message
    // =============================
    console.log(`\n[CHAT] User: "${message}"`);

    await chatRepo.addMessage(
        userId,
        conversationId,
        'user',
        message
    );

    // =============================
    // 3️⃣ Auto title update
    // =============================
    const conversation =
        await chatRepo.getConversation(userId, conversationId);

    if (
        conversation &&
        (conversation.title === "New Chat" ||
            conversation.title === "Pepper Farming Advice")
    ) {
        const title = generateTitle(message);

        if (title !== conversation.title) {
            await chatRepo.updateConversationTitle(
                userId,
                conversationId,
                title
            );
        }
    }

    // =============================
    // 4️⃣ Load memory + history
    // =============================
    const memory =
        await chatRepo.getConversationMemory(
            userId,
            conversationId
        );

    console.log(`[MEM] Loaded Firestore Summary: ${memory ? `"${memory}"` : "None"}`);

    const history =
        await chatRepo.getRecentMessages(
            userId,
            conversationId,
            6
        );

    // =============================
    // ⭐ Semantic Memory Retrieval
    // =============================
    let semanticMemories = [];

    try {
        semanticMemories =
            await searchRelevantMemories(
                userId,
                message
            );
    } catch (err) {
        console.error("❌ Semantic retrieval error:", err.message);
    }

    // =============================
    // 5️⃣ RAG
    // =============================
    const ragResult = await askPepperRAG({
        question: processMessageContent,
        history,
        memory,
        semanticMemories
    });

    let finalReply = ragResult.reply;

    // =============================
    // ⭐ Translation (To Local Language)
    // =============================
    if (language !== 'en') {
        try {
            const languageName = language === 'si' ? 'Sinhala' : 'Tamil';
            const completion = await openai.chat.completions.create({
                model: "gpt-4o-mini",
                messages: [
                    { role: "system", content: `You are an expert translator. Translate the following English agricultural advice into natural Sri Lankan ${languageName}.` },
                    { role: "user", content: finalReply }
                ]
            });
            finalReply = completion.choices[0].message.content;
            console.log(`[CHAT] Translated reply to ${language}: "${finalReply}"`);
        } catch (err) {
             console.error("Translation back failed:", err);
        }
    }

    // =============================
    // 6️⃣ Save assistant reply
    // =============================
    await chatRepo.addMessage(
        userId,
        conversationId,
        'assistant',
        finalReply,
        ragResult.sources
    );

    // =============================
    // 7️⃣ Memory Compression (Firestore)
    // =============================
    const compressionBatch =
        await chatRepo.getRecentMessages(
            userId,
            conversationId,
            10
        );

    if (compressionBatch.length >= 10) {
        console.log(`[COMPRESS] Triggered: Content length ${compressionBatch.length}. Summarizing...`);
        try {
            const newMemory =
                await summarizeConversation(
                    memory,
                    compressionBatch
                );

            await chatRepo.updateConversationMemory(
                userId,
                conversationId,
                newMemory
            );
            console.log("✅ New summary created and saved to Firestore");
        } catch (err) {
            console.warn("⚠️ Memory compression failed:", err.message);
        }
    } else {
        console.log(`[COMPRESS] Skipped: Only ${compressionBatch.length} messages in history`);
    }

    // =============================
    // ⭐ Store Semantic Memory
    // =============================
    try {
        const extracted =
            await extractMemory(processMessageContent);

        if (extracted) {
            console.log(`[EXTRACT] New Permanent Fact Found: "${extracted}"`);
            await saveMemory(userId, extracted);
            console.log("✅ Saved to Semantic Memory (Qdrant)");
        } else {
            console.log("[EXTRACT] No permanent facts found in this message.");
        }

    } catch (err) {
        console.error("❌ Semantic memory save error:", err.message);
    }

    return {
        conversationId,
        reply: finalReply,
        sources: ragResult.sources,
        suggestions: ragResult.suggestions || []
    };
};


/**
 * Conversation List
 */
export const getConversations = async (userId) => {
    return await chatRepo.getUserConversations(userId);
};


/**
 * Messages Loader
 */
export const getMessages = async (
    userId,
    conversationId
) => {
    return await chatRepo.getConversationMessages(
        userId,
        conversationId
    );
};