import path from 'path';
import fs from 'fs';
import { db } from '../config/firebase.js';

const COLLECTIONS_MAP = {
    soilTypes: 'soilTypes.json',
    districts: 'districts.json',
    pepperVarieties: 'pepperVarieties.json',
    agronomyTemplates: 'agronomyTemplates.json',
    agronomyGuides: 'agronomyGuides.json'
};

export const AgricultureController = {
    async getStatus(req, res) {
        try {
            const status = {};
            for (const name of Object.keys(COLLECTIONS_MAP)) {
                const snapshot = await db.collection(name).limit(1).get();
                const countSnapshot = await db.collection(name).count().get();
                status[name] = {
                    exists: !snapshot.empty,
                    count: countSnapshot.data().count
                };
            }
            res.status(200).json({ success: true, status });
        } catch (error) {
            console.error('Agriculture getStatus error:', error);
            res.status(500).json({ success: false, message: error.message });
        }
    },

    async seedCollection(req, res) {
        const { collection } = req.params;
        const { jsonData } = req.body; // New: support for custom JSON data
        const logs = [];

        try {
            if (jsonData) {
                // If custom data is provided, use it for the specified collection
                if (!COLLECTIONS_MAP[collection]) {
                    return res.status(400).json({ success: false, message: 'Invalid collection name for custom data' });
                }
                await performSeed(collection, logs, jsonData);
            } else if (collection === 'all') {
                for (const name of Object.keys(COLLECTIONS_MAP)) {
                    await performSeed(name, logs);
                }
            } else if (COLLECTIONS_MAP[collection]) {
                await performSeed(collection, logs);
            } else {
                return res.status(400).json({ success: false, message: 'Invalid collection name' });
            }

            res.status(200).json({ success: true, logs });
        } catch (error) {
            console.error(`Agriculture seed error (${collection}):`, error);
            res.status(500).json({ success: false, message: error.message, logs });
        }
    }
};

async function performSeed(name, logs, customData = null) {
    let data;

    if (customData) {
        data = customData;
        logs.push(`🚀 Importing custom data for ${name}...`);
    } else {
        const fileName = COLLECTIONS_MAP[name];
        const filePath = path.join(process.cwd(), fileName);

        if (!fs.existsSync(filePath)) {
            logs.push(`❌ ${name}: JSON file not found at ${filePath}`);
            return;
        }

        logs.push(`🚀 Importing ${name} from local file...`);
        data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    }

    // Proper batching for large collections (Firestore limit is 500 per batch)
    const entries = Object.entries(data);
    const totalCount = entries.length;

    for (let i = 0; i < entries.length; i += 500) {
        const chunk = entries.slice(i, i + 500);
        const batch = db.batch();
        for (const [id, doc] of chunk) {
            batch.set(db.collection(name).doc(id), doc);
        }
        await batch.commit();
    }

    logs.push(`✅ ${name} imported successfully (${totalCount} docs)`);
}
