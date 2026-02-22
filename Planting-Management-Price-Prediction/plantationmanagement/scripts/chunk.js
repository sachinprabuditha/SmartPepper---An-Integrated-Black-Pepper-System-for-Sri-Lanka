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

const CHUNK_SIZE = 500; // words
const OVERLAP = 100;

function chunkText(text) {
    const words = text.split(" ");
    const chunks = [];

    let start = 0;

    while (start < words.length) {
        const chunk = words.slice(start, start + CHUNK_SIZE).join(" ");
        chunks.push(chunk);

        start += CHUNK_SIZE - OVERLAP;
    }

    return chunks;
}

function processAll() {
    const files = fs.readdirSync(INPUT_DIR)
        .filter(f => f.endsWith(".txt"));

    for (const file of files) {
        const filePath = path.join(INPUT_DIR, file);
        const text = fs.readFileSync(filePath, "utf8");

        const chunks = chunkText(text);

        chunks.forEach((chunk, i) => {
            const outputName =
                file.replace(".txt", "") + `_chunk_${i + 1}.txt`;

            fs.writeFileSync(
                path.join(OUTPUT_DIR, outputName),
                chunk
            );
        });

        console.log(`✅ Chunked: ${file} (${chunks.length} chunks)`);
    }

    console.log("🎉 Chunking complete!");
}

processAll();
