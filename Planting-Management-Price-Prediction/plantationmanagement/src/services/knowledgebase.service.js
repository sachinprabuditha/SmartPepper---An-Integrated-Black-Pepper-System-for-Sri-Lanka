import fs from "fs";
import path from "path";
import * as pdfjsLib from "pdfjs-dist/legacy/build/pdf.mjs";
import OpenAI from "openai";
import { QdrantClient } from "@qdrant/js-client-rest";
import { fileURLToPath } from "url";
import "dotenv/config";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const BASE_DIR = path.join(__dirname, "../../rag_data");
const RAW_DIR = path.join(BASE_DIR, "raw_docs");
const EXTRACTED_DIR = path.join(BASE_DIR, "extracted_text");
const CLEANED_DIR = path.join(BASE_DIR, "cleaned_text");
const CHUNKS_DIR = path.join(BASE_DIR, "chunks");
const INDEXED_MARKER_DIR = path.join(BASE_DIR, "indexed_markers");

const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

const qdrant = new QdrantClient({
    url: process.env.QDRANT_URL,
    apiKey: process.env.QDRANT_API_KEY,
});

// Helper for cleaning
const cleanText = (text) => {
    return text
        .replace(/\s+/g, " ")
        .replace(/\n\s*\n/g, "\n")
        .replace(/Page\s+\d+/gi, "")
        .replace(/[-–—]{3,}/g, "")
        .replace(/\n\d+\n/g, "\n")
        .trim();
};

// Helper for chunking
const normalizeText = (text) => text.replace(/\s+/g, " ").replace(/\n+/g, " ").trim();
const splitIntoSentences = (text) => text.match(/[^.!?]+[.!?]+|[^.!?]+$/g) || [];
const CHUNK_SIZE = 500;
const OVERLAP = 120;

const chunkText = (text) => {
    text = normalizeText(text);
    const sentences = splitIntoSentences(text);
    const chunks = [];
    let currentChunk = [];
    let wordCount = 0;

    for (const sentence of sentences) {
        const words = sentence.split(" ").length;
        if (wordCount + words > CHUNK_SIZE) {
            chunks.push(currentChunk.join(" ").trim());
            const overlapWords = currentChunk.join(" ").split(" ").slice(-OVERLAP);
            currentChunk = [overlapWords.join(" "), sentence];
            wordCount = overlapWords.length + words;
        } else {
            currentChunk.push(sentence);
            wordCount += words;
        }
    }
    if (currentChunk.length > 0) chunks.push(currentChunk.join(" ").trim());
    return chunks;
};

const normalizeKeywordText = (text) =>
    text.toLowerCase().replace(/[^\w\s]/g, " ").replace(/\s+/g, " ").trim();

export const KnowledgeBaseService = {
    async getFiles() {
        if (!fs.existsSync(RAW_DIR)) fs.mkdirSync(RAW_DIR, { recursive: true });
        const files = fs.readdirSync(RAW_DIR).filter(f => f.toLowerCase().endsWith(".pdf"));

        return files.map(file => ({
            name: file,
            extracted: fs.existsSync(path.join(EXTRACTED_DIR, file.replace(".pdf", ".txt"))),
            cleaned: fs.existsSync(path.join(CLEANED_DIR, file.replace(".pdf", ".txt"))),
            chunked: fs.existsSync(CHUNKS_DIR) && fs.readdirSync(CHUNKS_DIR).some(f => f.startsWith(file.replace(".pdf", ""))),
        }));
    },

    async extractText(targetFiles = []) {
        if (!fs.existsSync(EXTRACTED_DIR)) fs.mkdirSync(EXTRACTED_DIR, { recursive: true });
        let files = fs.readdirSync(RAW_DIR).filter(f => f.toLowerCase().endsWith(".pdf"));

        // If specific files are requested, filter for them
        if (targetFiles.length > 0) {
            files = files.filter(f => targetFiles.includes(f));
        }

        const logs = [];

        for (const file of files) {
            const outputPath = path.join(EXTRACTED_DIR, file.replace(".pdf", ".txt"));

            // Incremental check: Skip if targetFiles is empty (incremental mode) and output exists
            if (targetFiles.length === 0 && fs.existsSync(outputPath)) {
                logs.push(`⏭️ Skipped (already extracted): ${file}`);
                continue;
            }

            try {
                const data = new Uint8Array(fs.readFileSync(path.join(RAW_DIR, file)));

                const pdf = await pdfjsLib.getDocument({
                    data,
                    standardFontDataUrl: path.join(__dirname, "../../node_modules/pdfjs-dist/standard_fonts/").replace(/\\/g, "/") + "/",
                    cMapUrl: path.join(__dirname, "../../node_modules/pdfjs-dist/cmaps/").replace(/\\/g, "/") + "/",
                    cMapPacked: true
                }).promise;

                let fullText = "";
                for (let i = 1; i <= pdf.numPages; i++) {
                    const page = await pdf.getPage(i);
                    const content = await page.getTextContent();
                    fullText += content.items.map(item => item.str).join(" ") + "\n\n";
                }
                fs.writeFileSync(outputPath, fullText);
                logs.push(`✅ Extracted: ${file}`);
            } catch (err) {
                logs.push(`❌ Failed: ${file} - ${err.message}`);
            }
        }
        return logs;
    },

    async cleanExtracted(targetFiles = []) {
        if (!fs.existsSync(CLEANED_DIR)) fs.mkdirSync(CLEANED_DIR, { recursive: true });
        let files = fs.readdirSync(EXTRACTED_DIR).filter(f => f.endsWith(".txt"));

        if (targetFiles.length > 0) {
            const targetTxtFiles = targetFiles.map(f => f.replace(".pdf", ".txt"));
            files = files.filter(f => targetTxtFiles.includes(f));
        }

        const logs = [];

        for (const file of files) {
            const outputPath = path.join(CLEANED_DIR, file);

            if (targetFiles.length === 0 && fs.existsSync(outputPath)) {
                logs.push(`⏭️ Skipped (already cleaned): ${file}`);
                continue;
            }

            const rawText = fs.readFileSync(path.join(EXTRACTED_DIR, file), "utf8");
            const cleaned = cleanText(rawText);
            fs.writeFileSync(outputPath, cleaned);
            logs.push(`✅ Cleaned: ${file}`);
        }
        return logs;
    },

    async chunkCleaned(targetFiles = []) {
        if (!fs.existsSync(CHUNKS_DIR)) fs.mkdirSync(CHUNKS_DIR, { recursive: true });
        let files = fs.readdirSync(CLEANED_DIR).filter(f => f.endsWith(".txt"));

        if (targetFiles.length > 0) {
            const targetTxtFiles = targetFiles.map(f => f.replace(".pdf", ".txt"));
            files = files.filter(f => targetTxtFiles.includes(f));
        }

        const logs = [];

        for (const file of files) {
            // For chunking, we check if ANY chunk exists for this file
            const baseName = file.replace(".txt", "");
            const existingChunks = fs.readdirSync(CHUNKS_DIR).filter(f => f.startsWith(baseName));

            if (targetFiles.length === 0 && existingChunks.length > 0) {
                logs.push(`⏭️ Skipped (already chunked): ${file}`);
                continue;
            }

            // Remove old chunks and markers if we are forcing/re-processing
            if (targetFiles.length > 0) {
                existingChunks.forEach(f => {
                    try {
                        fs.unlinkSync(path.join(CHUNKS_DIR, f));
                        const marker = path.join(INDEXED_MARKER_DIR, f + ".done");
                        if (fs.existsSync(marker)) fs.unlinkSync(marker);
                    } catch (e) { }
                });
            }

            const text = fs.readFileSync(path.join(CLEANED_DIR, file), "utf8");
            const chunks = chunkText(text);
            chunks.forEach((chunk, i) => {
                const outputName = baseName + `_chunk_${i + 1}.txt`;
                fs.writeFileSync(path.join(CHUNKS_DIR, outputName), chunk);
            });
            logs.push(`✅ Chunked: ${file} (${chunks.length} chunks)`);
        }
        return logs;
    },

    async indexToQdrant(targetFiles = []) {
        if (!fs.existsSync(CHUNKS_DIR)) return [];
        if (!fs.existsSync(INDEXED_MARKER_DIR)) fs.mkdirSync(INDEXED_MARKER_DIR, { recursive: true });

        let files = fs.readdirSync(CHUNKS_DIR);

        if (targetFiles.length > 0) {
            const baseNames = targetFiles.map(f => f.replace(".pdf", ""));
            files = files.filter(f => baseNames.some(base => f.startsWith(base)));
        }

        const logs = [];
        let idBase = Date.now();

        for (const file of files) {
            const markerPath = path.join(INDEXED_MARKER_DIR, file + ".done");

            // Incremental check: Skip if targetFiles is empty (incremental mode) and marker exists
            if (targetFiles.length === 0 && fs.existsSync(markerPath)) {
                logs.push(`⏭️ Skipped (already indexed): ${file}`);
                continue;
            }

            try {
                const text = fs.readFileSync(path.join(CHUNKS_DIR, file), "utf8");
                const embedding = await openai.embeddings.create({
                    model: "text-embedding-3-small",
                    input: text,
                });

                await qdrant.upsert("pepper_knowledge", {
                    points: [{
                        id: ++idBase,
                        vector: {
                            name: "dense",
                            vector: embedding.data[0].embedding
                        },
                        payload: {
                            text,
                            source: file,
                            domain: "black_pepper",
                            keyword_text: normalizeKeywordText(text),
                        },
                    }],
                });

                // Create marker
                fs.writeFileSync(markerPath, "");
                logs.push(`✅ Uploaded to Qdrant: ${file}`);
            } catch (err) {
                logs.push(`❌ Failed to upload: ${file} - ${err.message}`);
            }
        }
        return logs;
    },

    async getStatus() {
        const ensureDir = (dir) => { if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true }); };
        [RAW_DIR, EXTRACTED_DIR, CLEANED_DIR, CHUNKS_DIR, INDEXED_MARKER_DIR].forEach(ensureDir);

        const rawFiles = fs.readdirSync(RAW_DIR).filter(f => f.toLowerCase().endsWith(".pdf"));
        const extFiles = fs.readdirSync(EXTRACTED_DIR).filter(f => f.endsWith(".txt"));
        const cleanFiles = fs.readdirSync(CLEANED_DIR).filter(f => f.endsWith(".txt"));
        const chunkFiles = fs.readdirSync(CHUNKS_DIR).filter(f => f.endsWith(".txt"));

        // Calculate pending (incremental)
        const pending_extract = rawFiles.filter(f => !fs.existsSync(path.join(EXTRACTED_DIR, f.replace(".pdf", ".txt")))).length;
        const pending_clean = extFiles.filter(f => !fs.existsSync(path.join(CLEANED_DIR, f))).length;
        const pending_chunk = cleanFiles.filter(f => {
            if (!fs.existsSync(CHUNKS_DIR)) return true;
            const base = f.replace(".txt", "");
            return !fs.readdirSync(CHUNKS_DIR).some(cf => cf.startsWith(base));
        }).length;

        const pending_index = chunkFiles.filter(f => !fs.existsSync(path.join(INDEXED_MARKER_DIR, f + ".done"))).length;

        return {
            raw: rawFiles.length,
            extracted: extFiles.length,
            cleaned: cleanFiles.length,
            chunks: chunkFiles.length,
            pending: {
                extract: pending_extract,
                clean: pending_clean,
                chunk: pending_chunk,
                index: pending_index
            }
        };
    },

    async deleteFile(filename) {
        const logs = [];
        const baseName = filename.replace(".pdf", "");

        const pathsToDelete = [
            path.join(RAW_DIR, filename),
            path.join(EXTRACTED_DIR, baseName + ".txt"),
            path.join(CLEANED_DIR, baseName + ".txt")
        ];

        // Also find all chunks and markers
        if (fs.existsSync(CHUNKS_DIR)) {
            const chunks = fs.readdirSync(CHUNKS_DIR).filter(f => f.startsWith(baseName));
            chunks.forEach(chunk => {
                pathsToDelete.push(path.join(CHUNKS_DIR, chunk));
                pathsToDelete.push(path.join(INDEXED_MARKER_DIR, chunk + ".done"));
            });
        }

        for (const p of pathsToDelete) {
            if (fs.existsSync(p)) {
                try {
                    fs.unlinkSync(p);
                    logs.push(`🗑️ Deleted: ${path.basename(p)}`);
                } catch (err) {
                    logs.push(`❌ Failed to delete ${path.basename(p)}: ${err.message}`);
                }
            }
        }
        return logs;
    },

    async setupCollection() {
        const logs = [];
        try {
            try {
                await qdrant.deleteCollection("pepper_knowledge");
                logs.push("🧹 Old collection removed");
            } catch (e) {
                logs.push("ℹ️ No previous collection found, creating new...");
            }

            await qdrant.createCollection("pepper_knowledge", {
                vectors: {
                    dense: {
                        size: 1536,
                        distance: "Cosine",
                    },
                },
                sparse_vectors: {
                    sparse: {},
                },
            });
            logs.push("✅ Hybrid collection 'pepper_knowledge' created successfully!");
        } catch (err) {
            logs.push(`❌ Setup failed: ${err.message}`);
            throw err;
        }
        return logs;
    },

    async testConnection() {
        const logs = [];
        try {
            const collections = await qdrant.getCollections();
            logs.push("✅ Qdrant Connection: SUCCESS");
            logs.push(`📦 Collections found: ${collections.collections.map(c => c.name).join(", ")}`);
        } catch (err) {
            logs.push(`❌ Qdrant Connection: FAILED - ${err.message}`);
            throw err;
        }
        return logs;
    },

    async search(query) {
        const logs = [];
        try {
            logs.push(`🔎 Question: "${query}"`);

            const embedding = await openai.embeddings.create({
                model: "text-embedding-3-small",
                input: query,
            });

            const results = await qdrant.search("pepper_knowledge", {
                vector: {
                    name: "dense",
                    vector: embedding.data[0].embedding
                },
                limit: 3,
            });

            if (results.length === 0) {
                logs.push("⚠️ No relevant matches found in the knowledge base.");
            } else {
                results.forEach((r, i) => {
                    logs.push(`\n[Match ${i + 1} - Score: ${(r.score * 100).toFixed(1)}%]`);
                    logs.push(`📄 Source: ${r.payload.source}`);
                    logs.push(`📝 Snippet: ${r.payload.text.substring(0, 200)}...`);
                });
            }
        } catch (err) {
            logs.push(`❌ Search failed: ${err.message}`);
            throw err;
        }
        return logs;
    }
};
