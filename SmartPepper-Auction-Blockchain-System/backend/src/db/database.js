const logger = require('../utils/logger');

// Determine which database to use
let useMockDb = false;
let useFirebase = false;

// Check Firebase configuration
if (process.env.FIREBASE_PROJECT_ID || process.env.FIREBASE_SERVICE_ACCOUNT) {
  useFirebase = true;
  logger.info('Database: Using Firebase Firestore');
} else {
  // Use mock database for development
  useMockDb = true;
  logger.warn('Database: Firebase not configured, using in-memory mock database');
  logger.warn('To use Firebase, set FIREBASE_PROJECT_ID or FIREBASE_SERVICE_ACCOUNT in .env file');
}

// Load appropriate database
const firebase = useFirebase ? require('./firebase') : null;
const mockDb = useMockDb ? require('./mockDatabase') : null;

// Initialize Firebase if needed
if (useFirebase) {
  firebase.initializeFirebase();
}

module.exports = {
  query: (text, params) => {
    if (useMockDb) {
      return mockDb.query(text, params);
    }
    if (useFirebase) {
      // Firebase doesn't use SQL queries - this is for backward compatibility
      // Routes should be updated to use firebase.query methods directly
      logger.warn('SQL query attempted on Firebase - please update route to use Firebase queries');
      throw new Error('SQL queries not supported with Firebase. Use firebase.query methods instead.');
    }
    throw new Error('Database not configured');
  },
  
  connect: async () => {
    if (useMockDb) {
      return mockDb.connect();
    }
    if (useFirebase) {
      return firebase.connect();
    }
    throw new Error('Database not configured');
  },
  
  disconnect: () => {
    if (useMockDb) {
      return mockDb.disconnect();
    }
    if (useFirebase) {
      return firebase.disconnect();
    }
    return Promise.resolve();
  },
  
  isMock: useMockDb,
  isFirebase: useFirebase,
  
  // Export Firebase instance for direct access
  firebase: useFirebase ? firebase : null,
  
  // Export helper to get the appropriate db
  getDb: () => {
    if (useFirebase) return firebase.getDb();
    return null;
  },
  
  getAuth: () => {
    if (useFirebase) return firebase.getAuth();
    return null;
  }
};
