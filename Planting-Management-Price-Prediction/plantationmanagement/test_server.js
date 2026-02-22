import express from 'express';

const app = express();
const port = 5001;

app.get('/', (req, res) => {
    res.send('Test Server Running');
});

app.listen(port, () => {
    console.log(`Test Server running on port ${port}`);
});
