import { QdrantClient } from "@qdrant/js-client-rest";
import "dotenv/config";

const client = new QdrantClient({
    url: process.env.QDRANT_URL,
    apiKey: process.env.QDRANT_API_KEY,
});

await client.createCollection("farmer_memory", {
    vectors: {
        size: 1536,
        distance: "Cosine",
    },
});

console.log("✅ farmer_memory created");