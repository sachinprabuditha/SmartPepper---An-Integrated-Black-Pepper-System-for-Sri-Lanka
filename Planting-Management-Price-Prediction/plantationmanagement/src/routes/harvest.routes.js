import express from 'express';
import * as harvestController from '../controllers/harvest.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

// Season Routes
router.post('/seasons', harvestController.createSeason);
router.get('/farms/:farmId/seasons', harvestController.getSeasons);
router.get('/seasons/user/:userId', harvestController.getSeasonsByUser); // Path matches /api/seasons/user/:userId if mounted at /api
router.get('/seasons/:id', harvestController.getSeasonById);
router.post('/seasons/:id/end', harvestController.endSeason);
router.put('/seasons/:id', harvestController.updateSeason);
router.delete('/seasons/:id', harvestController.deleteSeason);

// Session Routes
router.post('/sessions', harvestController.createSession);
router.get('/seasons/:seasonId/sessions', harvestController.getSessions);
router.get('/sessions/season/:seasonId', harvestController.getSessions); // Alias for frontend compatibility
router.get('/sessions/:id', harvestController.getSessionById);
router.put('/sessions/:id', harvestController.updateSession);
router.delete('/sessions/:id', harvestController.deleteSession);

export default router;
