import OpenAI from "openai";
import { QdrantClient } from "@qdrant/js-client-rest";
import "dotenv/config";

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

const qdrant = new QdrantClient({
    url: process.env.QDRANT_URL,
    apiKey: process.env.QDRANT_API_KEY,
});

const COLLECTION = "farmer_memory";

/**
 * Retrieve relevant memories for a question
 */
export const searchRelevantMemories = async (
    userId,
    question
) => {

    const embedding =
        await openai.embeddings.create({
            model: "text-embedding-3-small",
            input: question,
        });

    const results = await qdrant.search(
        COLLECTION,
        {
            vector: embedding.data[0].embedding,
            limit: 5,
            with_payload: true,
            filter: {
                must: [
                    {
                        key: "userId",
                        match: { value: userId }
                    }
                ]
            }
        }
    );

    return results.map(r => r.payload.memory);
};