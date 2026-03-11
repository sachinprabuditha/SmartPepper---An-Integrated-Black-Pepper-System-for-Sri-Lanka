import { extractMemory } from './src/services/memory.extractor.js';

async function testExtractor() {
    console.log("=== Testing Simple Question ===");
    const res1 = await extractMemory("How to prepare land for new variety?");
    console.log(res1 ? `Extracted: ${res1}` : "Extracted: null (Correct, ignored purely question)");

    console.log("\n=== Testing Fact + Question ===");
    const res2 = await extractMemory("i want add 2 more hectares of land. what variety shoul i choose?");
    console.log(res2 ? `Extracted: ${res2}` : "Extracted: null (FAILED, ignored fact)");

    console.log("\n=== Testing Fact + Complex Question ===");
    const res3 = await extractMemory("so after this additional 2 hectares of land, my total land is 7 hectares . can you guess hoe many pepper vines available in my plantation");
    console.log(res3 ? `Extracted: ${res3}` : "Extracted: null (FAILED, ignored fact)");

    process.exit(0);
}

testExtractor();
