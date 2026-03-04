import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const INPUT_DIR = path.join(__dirname, "../rag_data/cleaned_text");
const OUTPUT_DIR = path.join(__dirname, "../rag_data/chunks");

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

const CHUNK_SIZE = 500;   // words
const OVERLAP = 120;      // slightly larger overlap

// ==============================
// Clean text (VERY IMPORTANT)
// ==============================
function normalizeText(text) {
    return text
        .replace(/\s+/g, " ")
        .replace(/\n+/g, " ")
        .trim();
}

// ==============================
// Sentence splitter
// ==============================
function splitIntoSentences(text) {
    return text.match(/[^.!?]+[.!?]+|[^.!?]+$/g) || [];
}

// ==============================
// Smart chunk builder
// ==============================
function chunkText(text) {

    text = normalizeText(text);

    const sentences = splitIntoSentences(text);

    const chunks = [];
    let currentChunk = [];
    let wordCount = 0;

    for (const sentence of sentences) {

        const words = sentence.split(" ").length;

        if (wordCount + words > CHUNK_SIZE) {

            chunks.push(currentChunk.join(" ").trim());

            // overlap
            const overlapWords =
                currentChunk.join(" ")
                    .split(" ")
                    .slice(-OVERLAP);

            currentChunk = [overlapWords.join(" "), sentence];
            wordCount = overlapWords.length + words;

        } else {
            currentChunk.push(sentence);
            wordCount += words;
        }
    }

    if (currentChunk.length > 0) {
        chunks.push(currentChunk.join(" ").trim());
    }

    return chunks;
}

// ==============================
// Process all files
// ==============================
function processAll() {

    const files = fs.readdirSync(INPUT_DIR)
        .filter(f => f.endsWith(".txt"));

    for (const file of files) {

        const filePath = path.join(INPUT_DIR, file);
        const text = fs.readFileSync(filePath, "utf8");

        const chunks = chunkText(text);

        chunks.forEach((chunk, i) => {

            const outputName =
                file.replace(".txt", "") +
                `_chunk_${i + 1}.txt`;

            fs.writeFileSync(
                path.join(OUTPUT_DIR, outputName),
                chunk
            );
        });

        console.log(`✅ Chunked: ${file} (${chunks.length} chunks)`);
    }

    console.log("🎉 Smart chunking complete!");
}

processAll();