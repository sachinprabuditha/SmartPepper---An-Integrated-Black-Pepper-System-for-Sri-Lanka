// src/services/chat.service.js

import { askPepperRAG } from './rag.service.js';
import * as chatRepo from '../repositories/chat.repository.js';

/**
 * Generate conversation title from first message
 */
const generateTitle = (message) => {

    if (!message) return "New Chat";

    let title = message.trim();

    // avoid useless titles
    const lowValueMessages = [
        "hi",
        "hello",
        "thanks",
        "ok",
        "okay",
        "yes",
        "no"
    ];

    if (lowValueMessages.includes(title.toLowerCase())) {
        return "Pepper Farming Advice";
    }

    // limit length
    if (title.length > 60) {
        title = title.substring(0, 57) + "...";
    }

    // clean trailing punctuation (optional NICE TOUCH)
    title = title.replace(/[?!.]+$/, '');

    // capitalize
    title =
        title.charAt(0).toUpperCase() +
        title.slice(1);

    return title;
};

/**
 * SIMPLE RAG CHAT SERVICE
 * Backend owns conversation history
 */
export const processMessage = async (
    userId,
    message,
    conversationId
) => {

    // create conversation if needed
    let isNewConversation = false;

    if (!conversationId || conversationId.trim() === "") {
        conversationId = await chatRepo.createConversation(userId);
        isNewConversation = true;
    }

    // save user message
    await chatRepo.addMessage(
        userId,
        conversationId,
        'user',
        message
    );

    // set title (Idempotent + Smart guard)
    const conversation = await chatRepo.getConversation(userId, conversationId);
    if (conversation && (conversation.title === "New Chat" || conversation.title === "Pepper Farming Advice")) {
        const title = generateTitle(message);

        // only update if new title is more meaningful than current one
        if (title !== conversation.title) {
            await chatRepo.updateConversationTitle(
                userId,
                conversationId,
                title
            );
        }
    }

    // run RAG
    const ragResult = await askPepperRAG({
        question: message
    });

    // save assistant reply
    await chatRepo.addMessage(
        userId,
        conversationId,
        'assistant',
        ragResult.reply,
        ragResult.sources
    );

    return {
        conversationId,
        reply: ragResult.reply,
        sources: ragResult.sources,
    };
};

/**
 *  NEW: Get conversation list for sidebar
 */
export const getConversations = async (userId) => {
    return await chatRepo.getUserConversations(userId);
};

/**
 * Get messages of a conversation
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
