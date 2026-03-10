import OpenAI from "openai";
import { QdrantClient } from "@qdrant/js-client-rest";
import "dotenv/config";

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

const qdrant = new QdrantClient({
    url: process.env.QDRANT_URL,
    apiKey: process.env.QDRANT_API_KEY,
    checkCompatibility: false,
});

const COLLECTION = "farmer_memory";

/**
 * Save semantic memory
 */
export const saveMemory = async (userId, memoryText) => {

    if (!memoryText) return;

    // create embedding
    const embedding =
        await openai.embeddings.create({
            model: "text-embedding-3-small",
            input: memoryText,
        });

    await qdrant.upsert(COLLECTION, {
        points: [
            {
                id: crypto.randomUUID(),
                vector: embedding.data[0].embedding,
                payload: {
                    userId,
                    memory: memoryText,
                    createdAt: new Date().toISOString()
                }
            }
        ]
    });
};