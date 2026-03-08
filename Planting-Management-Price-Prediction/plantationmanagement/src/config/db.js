import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';
import pg from 'pg'; // Explicitly import pg

dotenv.config();

const sequelize = new Sequelize(
    process.env.DB_NAME,
    process.env.DB_USER,
    process.env.DB_PASSWORD,
    {
        host: process.env.DB_HOST,
        dialect: 'postgres',
        port: process.env.DB_PORT,
        logging: false, // Set to console.log to see SQL queries
        dialectModule: pg // Ensure pg is used as driver
    }
);

export default sequelize;
