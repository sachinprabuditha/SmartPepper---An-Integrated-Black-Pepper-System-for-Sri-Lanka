import sequelize from '../config/db.js';
import PepperKnowledge from '../models/PepperKnowledge.js';
import { QueryTypes } from 'sequelize';
import OpenAI from 'openai';

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

export const generateEmbedding = async (text) => {
    const cleanText = text.replace(/\n/g, ' ');
    const response = await openai.embeddings.create({
        model: "text-embedding-3-small",
        input: cleanText,
    });
    return response.data[0].embedding;
};

export const searchKnowledge = async (embedding, hardDistrictId, hardVarietyId, hardPlantAgeMonths, category, softContext) => {
    // 1. Resolve Hard Context names from IDs (if needed) - For now assuming IDs/Names match or handled in controller
    // In this simplified JS version, we'll focus on the core vector search and filtering logic.

    let districtFilter = '';
    let varietyFilter = '';
    let ageFilter = '';
    const replacements = { category };

    // Strict Category Lock
    // Always filter by category

    // Hard Filters (Farmer Mode)
    if (hardDistrictId) {
        // Fetch district name logic would be here, for now assuming we pass names or ID mapping isn't crucial for this snippet
        // In the original C#, it resolved ID to Name. Let's assume passed values are what we match against or generic.
        // For simplicity in this port, we will skip the DB lookup for name and assume strict matching isn't possible without the name.
        // TODO: Enhance with District Name lookup if 'hardDistrictId' is passed.
    }

    // Soft Context Handling (Penalty Calculation) implemented in SQL or post-processing?
    // The C# version did 50 candidates -> in-memory sorting. We will do the same.

    // Basic SQL Vector Search
    // Note: Vector syntax depends on pgvector. 
    // We use <-> operator for L2 distance.

    const vectorString = `[${embedding.join(',')}]`;

    // Construct Where Clause
    let whereClause = `category = :category`;

    // Add Seasonality check
    const currentMonth = new Date().getMonth() + 1; // 1-12
    whereClause += ` AND (month_start IS NULL OR month_end IS NULL OR (:currentMonth BETWEEN month_start AND month_end))`;
    replacements.currentMonth = currentMonth;

    // Execute Raw Query
    const query = `
        SELECT *, (embedding <-> '${vectorString}') as distance
        FROM "pepperknowledge"
        WHERE ${whereClause}
        ORDER BY distance ASC
        LIMIT 50;
    `;

    const candidates = await sequelize.query(query, {
        replacements,
        type: QueryTypes.SELECT,
        model: PepperKnowledge,
        mapToModel: true
    });

    // Post-processing: Soft Ranking
    if (softContext) {
        return candidates.map(k => {
            let penalty = 0;
            // District Match
            if (softContext.districtName) {
                if (k.district === softContext.districtName) penalty -= 5;
                else if (k.district) penalty += 3;
            }

            // Variety Match
            if (softContext.varietyName) {
                if (k.variety === softContext.varietyName) penalty -= 5;
                else if (k.variety) penalty += 3;
            }

            // Age Match
            if (softContext.plantAgeMonths) {
                if ((!k.plant_age_min || k.plant_age_min <= softContext.plantAgeMonths) &&
                    (!k.plant_age_max || k.plant_age_max >= softContext.plantAgeMonths)) {
                    penalty -= 4;
                } else if (k.plant_age_min || k.plant_age_max) {
                    penalty += 2;
                }
            }

            return { item: k, finalScore: parseFloat(k.dataValues.distance) + (penalty * 0.01) }; // Hack to mix penalty into distance for sorting
        })
            .sort((a, b) => a.finalScore - b.finalScore)
            .slice(0, 15)
            .map(x => x.item);
    }

    return candidates.slice(0, 15);
};
