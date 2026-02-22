// src/services/rag.service.js

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

export const askPepperRAG = async ({ question }) => {

    // ✅ create embedding (NOW STRING)
    const embedding = await openai.embeddings.create({
        model: "text-embedding-3-small",
        input: question,
    });

    // search Qdrant
    const results = await qdrant.search("pepper_knowledge", {
        vector: embedding.data[0].embedding,
        limit: 4,
    });

    const context = results
        .map(r => r.payload.text)
        .join("\n\n");

    // generate answer
    const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
            {
                role: "system",
                content: ` You are a Sri Lankan black pepper agricultural assistant.

                    RULES:
                    - Use ONLY the provided context.
                    - Never invent information.
                    - If context does not contain the answer, say:
                    "No official recommendation available."
                    - Give short, clear, farmer-friendly advice.
                    - Prefer bullet points.
                    `
            },
            {
                role: "user",
                content: `Context:\n${context}\n\nQuestion:\n${question}`,
            },
        ],
    });

    return {
        reply:
            completion?.choices?.[0]?.message?.content ??
            "No official recommendation available.",
        sources: [...new Set(
            results.map(r =>
                r.payload.source
                    .replace("_chunk_", " — section ")
                    .replace(".txt", "")
                    .replaceAll("_", " ")
            )
        )],
    };
};
