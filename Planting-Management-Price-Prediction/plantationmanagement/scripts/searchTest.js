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

async function testSearch() {

    const question = "When should black pepper be planted?";

    // create embedding of question
    const embedding = await openai.embeddings.create({
        model: "text-embedding-3-small",
        input: question,
    });

    // search vector DB
    const results = await qdrant.search("pepper_knowledge", {
        vector: embedding.data[0].embedding,
        limit: 3,
    });

    console.log("\n🔎 Top Matches:\n");

    results.forEach((r, i) => {
        console.log(`Result ${i + 1}:`);
        console.log(r.payload.text.substring(0, 300));
        console.log("\n-----------------------\n");
    });
}

testSearch();
