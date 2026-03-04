import fs from "fs";
import path from "path";
import OpenAI from "openai";
import { QdrantClient } from "@qdrant/js-client-rest";
import { fileURLToPath } from "url";
import "dotenv/config";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const CHUNK_DIR = path.join(__dirname, "../rag_data/chunks");

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

const qdrant = new QdrantClient({
    url: process.env.QDRANT_URL,
    apiKey: process.env.QDRANT_API_KEY,
});

const normalizeKeywordText = (text) =>
    text
        .toLowerCase()
        .replace(/[^\w\s]/g, " ")
        .replace(/\s+/g, " ")
        .trim();

async function run() {

    const files = fs.readdirSync(CHUNK_DIR);

    let id = 1;

    for (const file of files) {

        const text = fs.readFileSync(
            path.join(CHUNK_DIR, file),
            "utf8"
        );

        // =========================
        // 1️⃣ Create embedding
        // =========================
        const embedding = await openai.embeddings.create({
            model: "text-embedding-3-small",
            input: text,
        });

        // =========================
        // 2️⃣ Upload HYBRID POINT
        // =========================
        await qdrant.upsert("pepper_knowledge", {
            points: [
                {
                    id: id++,

                    // ✅ CORRECT FOR JS SDK
                    vector: {
                        dense: embedding.data[0].embedding,
                    },

                    payload: {
                        text,
                        source: file,
                        domain: "black_pepper",

                        // keyword reranking
                        keyword_text: normalizeKeywordText(text),
                    },
                },
            ],
        });

        console.log(`✅ Uploaded: ${file}`);
    }

    console.log("🎉 All chunks embedded and uploaded!");
}

run();