import express from 'express';
import * as predictionController from '../controllers/prediction.controller.js';

const router = express.Router();

// Public route? .NET didn't have [Authorize] on controller or method in the snippet shown.
// However, Program.cs had `app.MapControllers()`. 
// If it was public, we keep it public. If unknown, safe to default to public for now or add auth if needed.
// The snippet for PredictionController.cs imports Microsoft.AspNetCore.Authorization but doesn't use [Authorize].
// So it is PUBLIC.

router.post('/predict', predictionController.predict);

export default router;
