import { getSeasonsByUser } from './src/services/harvest.service.js';

async function test() {
    try {
        console.log("Testing getSeasonsByUser...");
        const result = await getSeasonsByUser('4hgT8RyZYbLJsW9p65Tp');
        console.log("Success:", result);
    } catch (e) {
        console.error("Error:", e);
    }
    process.exit(0);
}

test();
