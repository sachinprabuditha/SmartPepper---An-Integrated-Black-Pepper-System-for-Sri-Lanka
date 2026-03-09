import { updateWeatherFeatures } from './src/services/weatherService.js';
import dotenv from 'dotenv';
dotenv.config();

console.log('Testing weather update job...');
updateWeatherFeatures().then(() => {
    console.log('Test completed.');
    process.exit(0);
}).catch(err => {
    console.error('Test failed:', err);
    process.exit(1);
});
