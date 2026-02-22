import { getFarmById } from './src/services/farm.service.js';
import sequelize from './src/config/db.js';

async function test() {
    try {
        const farmId = 'e8ae5e59-33d8-4718-b8ed-8a3be1b72ef8';
        const userId = '9cabaaef-753a-4764-a270-26d2e7f0c2fd'; // from recent logs

        // Ensure DB connection
        await sequelize.authenticate();

        const farm = await getFarmById(farmId, userId);
        console.log('Farm:', JSON.stringify(farm, null, 2));
    } catch (e) {
        console.error(e);
    } finally {
        // await sequelize.close(); // Keep it open or close safely
    }
}

test();
