import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

// ES module dirname fix
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const INPUT_DIR = path.join(__dirname, "../rag_data/extracted_text");
const OUTPUT_DIR = path.join(__dirname, "../rag_data/cleaned_text");

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

function cleanText(text) {
    return text
        // remove multiple spaces
        .replace(/\s+/g, " ")

        // remove excessive line breaks
        .replace(/\n\s*\n/g, "\n")

        // remove page numbers like "Page 1"
        .replace(/Page\s+\d+/gi, "")

        // remove long dashed separators
        .replace(/[-–—]{3,}/g, "")

        // remove isolated numbers (PDF artifacts)
        .replace(/\n\d+\n/g, "\n")

        // trim edges
        .trim();
}

function processAll() {
    const files = fs.readdirSync(INPUT_DIR)
        .filter(f => f.endsWith(".txt"));

    for (const file of files) {
        const inputPath = path.join(INPUT_DIR, file);
        const outputPath = path.join(OUTPUT_DIR, file);

        const rawText = fs.readFileSync(inputPath, "utf8");
        const cleaned = cleanText(rawText);

        fs.writeFileSync(outputPath, cleaned);

        console.log(`✅ Cleaned: ${file}`);
    }

    console.log("🎉 All text files cleaned!");
}

processAll();
