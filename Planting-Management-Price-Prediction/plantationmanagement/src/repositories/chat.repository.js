import { db, FieldValue } from '../config/firebase.js';
import { randomUUID } from 'crypto';

/**
 * Create new conversation
 */
export const createConversation = async (userId) => {
    const conversationId = randomUUID();

    await db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId)
        .set({
            title: 'New Chat',
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        });

    return conversationId;
};


/**
 * Add message to conversation
 */
export const addMessage = async (
    userId,
    conversationId,
    role,
    content,
    sources = []
) => {

    // ✅ Firestore safety guard
    if (!content) {
        console.warn("⚠️ Empty message prevented from saving");
        content = "No response generated.";
    }

    const messagesRef = db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    await messagesRef.add({
        role,
        content,
        sources: sources || [],
        timestamp: FieldValue.serverTimestamp(),
    });

    await db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId)
        .update({
            updatedAt: FieldValue.serverTimestamp(),
        });
};

export const getUserConversations = async (userId) => {

    const snapshot = await db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .orderBy('updatedAt', 'desc')
        .get();

    return snapshot.docs.map(doc => {
        const data = doc.data();

        return {
            id: doc.id,
            title: data.title,
            createdAt: data.createdAt?.toDate?.() || null,
            updatedAt: data.updatedAt?.toDate?.() || null,
        };
    });
};

/**
 * Get messages for a conversation
 */
export const getConversationMessages = async (
    userId,
    conversationId
) => {

    const snapshot = await db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', 'asc')
        .get();

    return snapshot.docs.map(doc => {
        const data = doc.data();

        return {
            id: doc.id,
            role: data.role,
            content: data.content,
            sources: data.sources || [],
            timestamp: data.timestamp?.toDate?.() || null
        };
    });
};

/**
 * Update conversation title
 */
export const updateConversationTitle = async (
    userId,
    conversationId,
    title
) => {

    await db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId)
        .update({
            title,
            updatedAt: FieldValue.serverTimestamp(),
        });
};

/**
 * Get single conversation
 */
export const getConversation = async (userId, conversationId) => {
    const doc = await db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!doc.exists) return null;

    const data = doc.data();
    return {
        id: doc.id,
        title: data.title,
        createdAt: data.createdAt?.toDate?.() || null,
        updatedAt: data.updatedAt?.toDate?.() || null,
    };
};
