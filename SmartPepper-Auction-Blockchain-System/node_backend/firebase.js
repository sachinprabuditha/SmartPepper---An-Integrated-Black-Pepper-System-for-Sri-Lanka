const admin = require('firebase-admin');

let db = null;
let auth = null;
let initialized = false;

/**
 * Initialize Firebase Admin SDK
 */
const initializeFirebase = () => {
  try {
    // Check if already initialized
    if (initialized) {
      console.log('Firebase already initialized');
      return { db, auth };
    }

    // Initialize with service account
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: process.env.FIREBASE_DATABASE_URL
      });
      
      console.log('✅ Firebase initialized with service account');
    } 
    // Initialize with application default credentials (for local development)
    else if (process.env.FIREBASE_PROJECT_ID) {
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID,
        databaseURL: process.env.FIREBASE_DATABASE_URL
      });
      
      console.log('✅ Firebase initialized with project ID');
    } else {
      throw new Error('❌ Firebase configuration is REQUIRED. Set FIREBASE_SERVICE_ACCOUNT or FIREBASE_PROJECT_ID in .env file');
    }

    db = admin.firestore();
    auth = admin.auth();
    initialized = true;

    // Configure Firestore settings
    db.settings({
      ignoreUndefinedProperties: true,
      timestampsInSnapshots: true
    });

    return { db, auth };
  } catch (error) {
    console.error('❌ Failed to initialize Firebase:', error.message);
    console.error('   Disease location storage will NOT work without Firebase.');
    console.error('   Please configure Firebase in .env file. See FIREBASE_DISEASE_INTEGRATION.md');
    throw error;
  }
};

/**
 * Get Firestore database instance
 */
const getDb = () => {
  if (!initialized) {
    initializeFirebase();
  }
  return db;
};

/**
 * Get Firebase Auth instance
 */
const getAuth = () => {
  if (!initialized) {
    initializeFirebase();
  }
  return auth;
};

module.exports = {
  initializeFirebase,
  getDb,
  getAuth
};
