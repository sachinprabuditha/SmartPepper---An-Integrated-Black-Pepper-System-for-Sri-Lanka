import express from 'express';
import * as agronomyController from '../controllers/agronomy.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authenticate);

// Routes compatible with Frontend
router.get('/guides', agronomyController.getGuides);
router.get('/guide', agronomyController.getGuides); // Alias for single guide fetch
router.get('/search', agronomyController.getGuides); // Alias for search
router.get('/templates', agronomyController.getTemplates);

router.get('/districts', agronomyController.getDistricts);
router.get('/districts/:districtId/soils', agronomyController.getSoilsByDistrict);
router.get('/districts/:districtId/soils/:soilTypeId/varieties', agronomyController.getVarietiesByContext);
router.get('/soil-types', agronomyController.getSoilTypes);
router.get('/varieties', agronomyController.getVarieties);

export default router;
