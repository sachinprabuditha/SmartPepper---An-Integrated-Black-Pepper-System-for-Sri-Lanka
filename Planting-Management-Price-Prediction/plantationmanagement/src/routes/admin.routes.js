import express from 'express';
import * as adminController from '../controllers/admin.controller.js';

const router = express.Router();

// Admin routes usually protected. .NET had commented out [Authorize].
// We will leave it public for now to match, or add auth if requested.
// Route: api/admin/pepperknowledge

router.post('/', adminController.createKnowledge);
router.post('/seed', adminController.triggerSeed);

export default router;
