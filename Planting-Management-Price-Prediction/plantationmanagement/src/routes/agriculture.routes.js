import express from 'express';
import { AgricultureController } from '../controllers/agriculture.controller.js';

const router = express.Router();

router.get('/status', AgricultureController.getStatus);
router.post('/seed/:collection', AgricultureController.seedCollection);

export default router;
