// src/services/chat.service.js

import { askPepperRAG } from './rag.service.js';
import * as chatRepo from '../repositories/chat.repository.js';
import { summarizeConversation } from './memory.service.js';

import { extractMemory } from './memory.extractor.js';
import { saveMemory } from '../repositories/memory.vector.repository.js';
import { searchRelevantMemories } from './memory.search.service.js';

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
    conversationId
) => {

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
        console.warn("Semantic retrieval skipped");
    }

    // =============================
    // 5️⃣ RAG
    // =============================
    const ragResult = await askPepperRAG({
        question: message,
        history,
        memory,
        semanticMemories
    });

    // =============================
    // 6️⃣ Save assistant reply
    // =============================
    await chatRepo.addMessage(
        userId,
        conversationId,
        'assistant',
        ragResult.reply,
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
        } catch (err) {
            console.warn("Memory compression skipped");
        }
    }

    // =============================
    // ⭐ Store Semantic Memory
    // =============================
    try {

        const extracted =
            await extractMemory(message);

        if (extracted) {
            await saveMemory(userId, extracted);
        }

    } catch (err) {
        console.warn("Semantic memory save skipped");
    }

    return {
        conversationId,
        reply: ragResult.reply,
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