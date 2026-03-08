import { db, FieldValue } from '../config/firebase.js';
import { randomUUID } from 'crypto';

/**
 * =============================
 * Create Conversation
 * =============================
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
            memory: "", // ⭐ long-term memory
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        });

    return conversationId;
};


/**
 * =============================
 * Add Message
 * =============================
 */
export const addMessage = async (
    userId,
    conversationId,
    role,
    content,
    sources = []
) => {

    if (!content) {
        console.warn("⚠️ Empty message prevented from saving");
        content = "No response generated.";
    }

    const conversationRef = db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId);

    const messagesRef = conversationRef.collection('messages');

    await messagesRef.add({
        role,
        content,
        sources,
        timestamp: FieldValue.serverTimestamp(),
    });

    await conversationRef.update({
        updatedAt: FieldValue.serverTimestamp(),
    });
};


/**
 * =============================
 * Conversation List
 * =============================
 */
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
 * =============================
 * Get Messages
 * =============================
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
 * =============================
 * Get Conversation
 * =============================
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
        memory: data.memory || "",
        createdAt: data.createdAt?.toDate?.() || null,
        updatedAt: data.updatedAt?.toDate?.() || null,
    };
};


/**
 * =============================
 * Update Title
 * =============================
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
 * =============================
 * MEMORY FUNCTIONS
 * =============================
 */

/**
 * Get stored memory
 */
export const getConversationMemory = async (
    userId,
    conversationId
) => {

    const conversation = await getConversation(
        userId,
        conversationId
    );

    return conversation?.memory || "";
};


/**
 * Update compressed memory
 */
export const updateConversationMemory = async (
    userId,
    conversationId,
    memory
) => {

    await db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId)
        .update({
            memory: memory || "",
            updatedAt: FieldValue.serverTimestamp(),
        });
};


/**
 * =============================
 * Recent Messages (Compression)
 * =============================
 */
export const getRecentMessages = async (
    userId,
    conversationId,
    limit = 8
) => {

    const snapshot = await db
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', 'desc')
        .limit(limit)
        .get();

    // return oldest → newest
    return snapshot.docs
        .map(doc => doc.data())
        .reverse();
};