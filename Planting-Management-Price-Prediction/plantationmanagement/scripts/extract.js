import fs from "fs";
import path from "path";
import * as pdfjsLib from "pdfjs-dist/legacy/build/pdf.mjs";
import { fileURLToPath } from "url";

// fix dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const RAW_DIR = path.join(__dirname, "../rag_data/raw_docs");
const OUTPUT_DIR = path.join(__dirname, "../rag_data/extracted_text");

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

async function extractTextFromPDF(filePath) {
    const data = new Uint8Array(fs.readFileSync(filePath));

    const pdf = await pdfjsLib.getDocument({ data }).promise;

    let fullText = "";

    for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const content = await page.getTextContent();

        const pageText = content.items.map(item => item.str).join(" ");
        fullText += pageText + "\n\n";
    }

    return fullText;
}

async function processAll() {
    const files = fs.readdirSync(RAW_DIR)
        .filter(f => f.toLowerCase().endsWith(".pdf"));

    for (const file of files) {
        try {
            const filePath = path.join(RAW_DIR, file);

            const text = await extractTextFromPDF(filePath);

            const outputPath = path.join(
                OUTPUT_DIR,
                file.replace(".pdf", ".txt")
            );

            fs.writeFileSync(outputPath, text);

            console.log(`✅ Extracted: ${file}`);
        } catch (err) {
            console.error(`❌ Failed: ${file}`, err.message);
        }
    }

    console.log("🎉 All PDFs processed!");
}

processAll();
