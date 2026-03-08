import PepperKnowledge from '../models/PepperKnowledge.js';
import * as knowledgeService from '../services/knowledge.service.js';

export const createKnowledge = async (req, res) => {
    try {
        const request = req.body;

        // Generate Embedding
        const embedding = await knowledgeService.generateEmbedding(request.Content);
        // Note: Sequelize doesn't support vector type natively easily without raw query or extension.
        // We store it as a string/array representation if using pgvector via sequelize-pgvector or just raw.
        // In our model, we defined embedding as DataTypes.STRING (or ARRAY if configured).
        // pgvector usually expects string format '[1,2,3]' for insertion.

        // IMPORTANT: Ensure the embedding is formatted correctly for Postgres vector
        const embeddingString = JSON.stringify(embedding); // '[...]'

        const newKnowledge = await PepperKnowledge.create({
            category: request.Category,
            sub_category: request.SubCategory,
            district: request.District,
            variety: request.Variety,
            plant_age_min: request.PlantAgeMin,
            plant_age_max: request.PlantAgeMax,
            month_start: request.MonthStart,
            month_end: request.MonthEnd,
            title: request.Title,
            content: request.Content,
            source: request.Source,
            confidence_level: request.ConfidenceLevel,
            embedding: embeddingString
        });

        res.status(200).json({ Message: "Knowledge created successfully", Id: newKnowledge.id });
    } catch (error) {
        console.error('Create knowledge error:', error);
        res.status(500).json({ Message: "An error occurred while saving knowledge." });
    }
};

export const triggerSeed = async (req, res) => {
    // Seeding logic is usually complex file reading. 
    // For now, we'll return a stub or implement a basic seeder if file exists.
    res.status(200).json({ Message: "Seeding not implemented in this version yet." });
};
