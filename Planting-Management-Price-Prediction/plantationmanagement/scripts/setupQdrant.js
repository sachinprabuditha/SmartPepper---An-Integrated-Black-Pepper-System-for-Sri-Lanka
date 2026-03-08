import { QdrantClient } from "@qdrant/js-client-rest";
import "dotenv/config";

const client = new QdrantClient({
    url: process.env.QDRANT_URL,
    apiKey: process.env.QDRANT_API_KEY,
});

async function setup() {

    // delete old collection if exists (safe reset)
    try {
        await client.deleteCollection("pepper_knowledge");
        console.log("🧹 Old collection removed");
    } catch (e) {
        console.log("No previous collection found");
    }

    // ✅ HYBRID COLLECTION
    await client.createCollection("pepper_knowledge", {
        vectors: {
            dense: {
                size: 1536,          // OpenAI embedding size
                distance: "Cosine",
            },
        },

        sparse_vectors: {
            sparse: {},              // enables keyword search
        },
    });

    console.log("✅ Hybrid collection created!");
}

setup();