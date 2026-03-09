import axios from 'axios';

async function run() {
    try {
        console.log('Testing prediction API...');
        const response = await axios.post('http://localhost:5000/api/prediction/predict', {
            usdBuyRate: 300,
            usdSellRate: 310,
            temperature: 28,
            precipitation: 5,
            date: "2026-03-09T00:00:00.000Z",
            location: "Colombo",
            grade: "GR-2"
        });
        console.log('Success:', response.data);
    } catch (e) {
        if (e.response) {
            console.error('Error response:', e.response.status, e.response.data);
        } else {
            console.error('Error:', e.message);
        }
    }
}
run();
