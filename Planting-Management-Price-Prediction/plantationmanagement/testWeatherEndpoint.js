import axios from 'axios';

async function testWeather() {
    try {
        console.log("Fetching weather for Colombo...");
        const response = await axios.get("http://localhost:5000/api/prediction/weather/Colombo");
        console.log("Success:", response.data);
    } catch (e) {
        console.error("Error:", e.response ? e.response.data : e.message);
    }
}

testWeather();
