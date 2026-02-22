import { QdrantClient } from "@qdrant/js-client-rest";
import "dotenv/config";

const client = new QdrantClient({
    url: process.env.QDRANT_URL,
    apiKey: process.env.QDRANT_API_KEY,
});

async function setup() {
    await client.createCollection("pepper_knowledge", {
        vectors: {
            size: 1536,
            distance: "Cosine",
        },
    });

    console.log("✅ pepper_knowledge collection created!");
}

setup();
