import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';


dotenv.config();

const app = express();
const port = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
    console.log(`${req.method} ${req.url}`);
    next();
});

import authRoutes from './routes/auth.routes.js';
app.use('/api/auth', authRoutes);

import farmRoutes from './routes/farm.routes.js';
app.use('/api/plantation', farmRoutes); // Matches /api/plantation/farms

import agronomyRoutes from './routes/agronomy.routes.js';
app.use('/api/agronomy', agronomyRoutes); // Matches /api/agronomy/districts

import chatRoutes from './routes/chat.routes.js';
app.use('/api/chat', chatRoutes);

import predictionRoutes from './routes/prediction.routes.js';
app.use('/api/prediction', predictionRoutes);



import knowledgebaseRoutes from './routes/knowledgebase.routes.js';
import agricultureRoutes from './routes/agriculture.routes.js';
app.use('/api/kb', knowledgebaseRoutes);
app.use('/api/agriculture', agricultureRoutes);

import harvestRoutes from './routes/harvest.routes.js';
app.use('/api', harvestRoutes); // Matches /api/seasons/user/:userId - broad mount moved to end

// Test route
app.get('/', (req, res) => {
    res.send('Plantation Management Backend is running!');
});

// Database connection test
const startServer = async () => {
    try {
        console.log('Firebase (Firestore) initialized via config.');

        app.listen(port, "0.0.0.0", () => {
            console.log(`Server running on port ${port}`);
        });

    } catch (error) {
        console.error('Unable to connect to the database:', error);
    }
};

startServer();
