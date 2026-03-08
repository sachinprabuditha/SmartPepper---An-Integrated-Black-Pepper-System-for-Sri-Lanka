import { QdrantClient } from "@qdrant/js-client-rest";
import "dotenv/config";

const client = new QdrantClient({
    url: process.env.QDRANT_URL,
    apiKey: process.env.QDRANT_API_KEY,
});

console.log("Starting...");
client.createPayloadIndex("farmer_memory", {
    field_name: "userId",
    field_schema: "keyword",
}).then(res => {
    console.log("Success:", res);
    process.exit(0);
}).catch(err => {
    console.error("Error:", err);
    process.exit(1);
});
