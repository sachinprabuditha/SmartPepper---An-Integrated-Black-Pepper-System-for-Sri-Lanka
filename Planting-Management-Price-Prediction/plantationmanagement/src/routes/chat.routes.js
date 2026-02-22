import express from 'express';
import * as chatController from '../controllers/chat.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

router.post('/', chatController.sendMessage);

router.get(
    '/conversations',
    chatController.getConversations
);

router.get(
    '/conversations/:conversationId/messages',
    chatController.getMessages
);

export default router;
