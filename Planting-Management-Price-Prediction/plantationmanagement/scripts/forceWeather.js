import { updateWeatherFeatures } from '../src/services/weatherService.js';
import dotenv from 'dotenv';
dotenv.config();

console.log('Force running weather update...');
updateWeatherFeatures().then(() => {
    console.log('Weather update executed.');
    process.exit(0);
}).catch(err => {
    console.error('Error:', err);
    process.exit(1);
});
