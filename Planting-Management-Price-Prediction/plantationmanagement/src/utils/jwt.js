import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import crypto from 'crypto';

dotenv.config();

const SECRET_KEY = process.env.JWT_SECRET || 'fallback_secret';
const EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1d';

/**
 * Generate a JWT token for a user
 * @param {object} user - User object (must have id, email, fullName)
 * @returns {string} JWT token
 */
export const generateToken = (user) => {
    const payload = {
        nameid: user.id, // Standard claim for ID
        email: user.email,
        unique_name: user.fullName,
        jti: crypto.randomUUID() // Unique ID for token
    };

    return jwt.sign(payload, SECRET_KEY, { expiresIn: EXPIRES_IN, issuer: 'HarvestTrackingAPI', audience: 'HarvestTrackingClient' });
};

/**
 * Verify a JWT token
 * @param {string} token - JWT token string
 * @returns {object|null} Decoded payload or null if invalid
 */
export const verifyToken = (token) => {
    try {
        return jwt.verify(token, SECRET_KEY, { issuer: 'HarvestTrackingAPI', audience: 'HarvestTrackingClient' });
    } catch (error) {
        return null;
    }
};
