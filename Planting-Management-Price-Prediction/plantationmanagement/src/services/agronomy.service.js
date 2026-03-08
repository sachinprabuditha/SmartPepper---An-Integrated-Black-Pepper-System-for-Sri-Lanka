
import admin from 'firebase-admin';
import { db } from '../config/firebase.js';

export const getGuides = async (districtId, soilTypeId, varietyId) => {
    let query = db.collection('agronomyGuides');

    if (districtId) query = query.where('districtId', '==', districtId);
    if (soilTypeId) query = query.where('soilTypeId', '==', soilTypeId);
    if (varietyId) query = query.where('varietyId', '==', varietyId);

    const snapshot = await query.get();

    if (snapshot.empty) return [];

    // 1. Get all guides
    const guides = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // 2. Extract unique variety IDs
    const uniqueVarietyIds = [...new Set(guides.map(g => g.varietyId).filter(id => id))];

    if (uniqueVarietyIds.length === 0) return guides;

    // 3. Fetch all related varieties (using 'in' query if <= 10, or multiple fetches)
    // Assuming small number of varieties per district/soil query
    // Optimizing for Firestore 'in' query limits (max 10)
    let varieties = [];
    const chunks = [];
    for (let i = 0; i < uniqueVarietyIds.length; i += 10) {
        chunks.push(uniqueVarietyIds.slice(i, i + 10));
    }

    for (const chunk of chunks) {
        const varSnapshot = await db.collection('pepperVarieties').where(admin.firestore.FieldPath.documentId(), 'in', chunk).get();
        varieties.push(...varSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    }

    const varietyMap = new Map(varieties.map(v => [v.id, v]));

    // 4. Merge details
    return guides.map(guide => {
        const variety = varietyMap.get(guide.varietyId) || {};
        const specs = variety.plantingSpecifications || {};

        return {
            id: guide.id,
            districtId: guide.districtId,
            districtName: guide.districtName || '', // Can be enhanced by fetching district name if needed
            soilTypeId: guide.soilTypeId,
            soilTypeName: guide.soilTypeName || '',
            varietyId: guide.varietyId,
            // Denormalize/Merge Variety Details
            varietyName: variety.name || guide.varietyName || '',
            varietySpecialities: variety.specialities || guide.varietySpecialities || '',
            varietySuitabilityReason: variety.suitabilityReason || guide.varietySuitabilityReason || '',
            varietySoilTypeRecommendation: variety.soilTypeRecommendation || guide.varietySoilTypeRecommendation || '',
            varietySpacingMeters: specs.spacingMeters || guide.varietySpacingMeters || '',
            varietyVinesPerHectare: specs.vinesPerHectare || guide.varietyVinesPerHectare || null,
            varietyPitDimensionsCm: specs.pitDimensionsCm || guide.varietyPitDimensionsCm || '',
            steps: guide.steps || []
        };
    });
};

export const getTemplates = async () => {
    const snapshot = await db.collection('agronomyTemplates').get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const getTemplatesByVarietyKeys = async (varietyKeys) => {
    // Firestore 'in' query supports up to 10 values
    const snapshot = await db.collection('agronomyTemplates')
        .where('varietyKey', 'in', varietyKeys)
        .get();

    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// Removed component getters as they are now in component.service.js
