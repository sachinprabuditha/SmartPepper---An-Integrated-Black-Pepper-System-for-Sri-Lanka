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
 * Retrieve relevant memories for a question
 */
export const searchRelevantMemories = async (
    userId,
    question
) => {

    if (!userId) {
        console.warn("⚠️ No userId provided for semantic search");
        return [];
    }

    let embedding = null;
    try {
        embedding =
            await openai.embeddings.create({
                model: "text-embedding-3-small",
                input: question,
            });

        const vector = embedding.data[0].embedding;

        const results = await qdrant.search(
            COLLECTION,
            {
                // Ensure vector is passed correctly for unnamed vectors
                vector: vector,
                limit: 5,
                with_payload: true,
                filter: {
                    must: [
                        {
                            key: "userId",
                            match: {
                                value: userId
                            }
                        }
                    ]
                }
            }
        );

        const memories = results.map(r => r.payload.memory);

        if (memories.length > 0) {
            console.log(`✅ Retrieved ${memories.length} relevant long-term memories`);
            memories.forEach((m, i) => console.log(`   [${i + 1}] ${m}`));
        } else {
            console.log("ℹ️ No relevant long-term memories found for this query.");
        }

        return memories;
    } catch (err) {
        // ⭐ EXTRACT DEEP ERROR FROM QDRANT
        const deepError = err.data?.status?.error || err.data || "No deep error info";

        console.error("❌ QDRANT REJECTION DETAIL:", deepError);
        console.error("Debug Info:", {
            userId,
            vectorSize: embedding?.data?.[0]?.embedding?.length || "Unknown",
            collection: COLLECTION
        });

        throw err;
    }
};