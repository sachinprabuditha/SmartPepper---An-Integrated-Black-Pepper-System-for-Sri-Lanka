import bcrypt from 'bcrypt';

const SALT_ROUNDS = 10;

/**
 * Hash a password using bcrypt
 * @param {string} password - plain text password
 * @returns {Promise<string>} hashed password
 */
export const hashPassword = async (password) => {
    return await bcrypt.hash(password, SALT_ROUNDS);
};

/**
 * Verify a password against a hash
 * @param {string} password - plain text password
 * @param {string} hash - existing hash
 * @returns {Promise<boolean>} true if match
 */
export const verifyPassword = async (password, hash) => {
    return await bcrypt.compare(password, hash);
};
