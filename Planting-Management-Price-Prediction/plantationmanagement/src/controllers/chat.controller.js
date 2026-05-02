import * as chatService from '../services/chat.service.js';

export const sendMessage = async (req, res) => {
    try {
        const userId = req.user.nameid;

        // ✅ correct fields
        const { message, conversationId, language } = req.body;

        if (!message || message.trim() === "") {
            return res.status(400).json({
                success: false,
                message: 'Message cannot be empty'
            });
        }

        // ✅ correct parameter order
        const result = await chatService.processMessage(
            userId,
            message,
            conversationId,
            language
        );

        res.status(200).json({
            success: true,
            message: 'Response generated',
            data: result
        });

    } catch (error) {
        console.error('Chat error:', error);

        res.status(500).json({
            success: false,
            message: 'An error occurred while processing your message'
        });
    }
};

export const getConversations = async (req, res) => {
    try {
        const userId = req.user.nameid;

        const conversations =
            await chatService.getConversations(userId);

        res.status(200).json({
            success: true,
            data: conversations
        });

    } catch (error) {
        console.error("Get conversations error:", error);

        res.status(500).json({
            success: false,
            message: "Failed to load conversations"
        });
    }
};

export const getMessages = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { conversationId } = req.params;

        const messages = await chatService.getMessages(
            userId,
            conversationId
        );

        res.status(200).json({
            success: true,
            data: messages
        });

    } catch (error) {
        console.error("Get messages error:", error);

        res.status(500).json({
            success: false,
            message: "Failed to load messages"
        });
    }
};
