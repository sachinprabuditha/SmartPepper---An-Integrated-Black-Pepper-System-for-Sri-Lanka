import admin from 'firebase-admin';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (error) {
        const serviceAccountPath = path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT);

        if (fs.existsSync(serviceAccountPath)) {
            serviceAccount = JSON.parse(
                fs.readFileSync(serviceAccountPath, 'utf8')
            );
        } else {
            throw new Error(
                `FIREBASE_SERVICE_ACCOUNT invalid: ${process.env.FIREBASE_SERVICE_ACCOUNT}`
            );
        }
    }
} else {
    throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable is missing.');
}

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue; // ⭐ ADD THIS

export { db, FieldValue }; // ⭐ EXPORT BOTH
