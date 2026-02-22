import express from 'express';
import * as farmController from '../controllers/farm.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate); // Protect all routes

// Mounted at /api/plantation, so this becomes /api/plantation/farms
router.post('/start', farmController.createFarm); // Alias for starting plantation
router.post('/farms', farmController.createFarm);
router.get('/farms', farmController.getFarms);
router.get('/farms/:id', farmController.getFarmById);
router.get('/farm/:id', farmController.getFarmById); // Alias
router.put('/farms/:id', farmController.updateFarm);
router.put('/farm/:id', farmController.updateFarm); // Alias
router.delete('/farms/:id', farmController.deleteFarm);
router.delete('/farm/:id', farmController.deleteFarm); // Alias

// Tasks routes
router.get('/tasks/:farmId', farmController.getTasksByFarmId);
router.put('/task/complete/:id', farmController.completeTask);
router.put('/tasks/:id/completion', farmController.completeTask); // Alias for frontend compatibility
router.post('/tasks/manual', farmController.createManualTask);
router.put('/tasks/:id', farmController.updateTask);
router.delete('/tasks/:id', farmController.deleteTask);

export default router;
