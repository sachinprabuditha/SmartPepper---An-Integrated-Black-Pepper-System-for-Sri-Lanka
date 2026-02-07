const admin = require('firebase-admin');
const logger = require('../utils/logger');

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
      logger.info('Firebase already initialized');
      return { db, auth };
    }

    // Initialize with service account
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: process.env.FIREBASE_DATABASE_URL
      });
      
      logger.info('Firebase initialized with service account');
    } 
    // Initialize with application default credentials (for local development)
    else if (process.env.FIREBASE_PROJECT_ID) {
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID,
        databaseURL: process.env.FIREBASE_DATABASE_URL
      });
      
      logger.info('Firebase initialized with project ID');
    } else {
      throw new Error('Firebase configuration missing. Set FIREBASE_SERVICE_ACCOUNT or FIREBASE_PROJECT_ID in .env');
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
    logger.error('Failed to initialize Firebase:', error);
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

/**
 * Query helper functions to match PostgreSQL-like syntax
 */
const query = {
  /**
   * Execute a Firestore query
   * @param {string} collection - Collection name
   * @param {object} options - Query options
   * @returns {Promise<object>} - Query results
   */
  async select(collection, options = {}) {
    const db = getDb();
    let ref = db.collection(collection);

    // Apply filters
    if (options.where) {
      for (const [field, operator, value] of options.where) {
        ref = ref.where(field, operator, value);
      }
    }

    // Apply ordering
    if (options.orderBy) {
      for (const [field, direction = 'asc'] of options.orderBy) {
        ref = ref.orderBy(field, direction);
      }
    }

    // Apply limit
    if (options.limit) {
      ref = ref.limit(options.limit);
    }

    // Apply offset (using startAfter with document)
    if (options.offset && options.lastDoc) {
      ref = ref.startAfter(options.lastDoc);
    }

    const snapshot = await ref.get();
    
    return {
      rows: snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })),
      rowCount: snapshot.size
    };
  },

  /**
   * Insert a document
   * @param {string} collection - Collection name
   * @param {object} data - Data to insert
   * @returns {Promise<object>} - Inserted document
   */
  async insert(collection, data) {
    const db = getDb();
    const docRef = await db.collection(collection).add({
      ...data,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    const doc = await docRef.get();
    return {
      rows: [{
        id: doc.id,
        ...doc.data()
      }],
      rowCount: 1
    };
  },

  /**
   * Update a document
   * @param {string} collection - Collection name
   * @param {string} docId - Document ID
   * @param {object} data - Data to update
   * @returns {Promise<object>} - Updated document
   */
  async update(collection, docId, data) {
    const db = getDb();
    const docRef = db.collection(collection).doc(docId);
    
    await docRef.update({
      ...data,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    const doc = await docRef.get();
    return {
      rows: [{
        id: doc.id,
        ...doc.data()
      }],
      rowCount: 1
    };
  },

  /**
   * Delete a document
   * @param {string} collection - Collection name
   * @param {string} docId - Document ID
   * @returns {Promise<object>} - Delete result
   */
  async delete(collection, docId) {
    const db = getDb();
    await db.collection(collection).doc(docId).delete();
    
    return {
      rows: [],
      rowCount: 1
    };
  },

  /**
   * Get a single document by ID
   * @param {string} collection - Collection name
   * @param {string} docId - Document ID
   * @returns {Promise<object>} - Document data
   */
  async getById(collection, docId) {
    const db = getDb();
    const doc = await db.collection(collection).doc(docId).get();
    
    if (!doc.exists) {
      return { rows: [], rowCount: 0 };
    }

    return {
      rows: [{
        id: doc.id,
        ...doc.data()
      }],
      rowCount: 1
    };
  },

  /**
   * Count documents in a collection
   * @param {string} collection - Collection name
   * @param {object} options - Query options
   * @returns {Promise<number>} - Count
   */
  async count(collection, options = {}) {
    const result = await this.select(collection, options);
    return result.rowCount;
  },

  /**
   * Batch operations
   */
  batch() {
    const db = getDb();
    return db.batch();
  },

  /**
   * Transaction
   */
  transaction(updateFunction) {
    const db = getDb();
    return db.runTransaction(updateFunction);
  }
};

/**
 * Connect to Firebase (initialization check)
 */
const connect = async () => {
  try {
    if (!initialized) {
      initializeFirebase();
    }
    
    // Test connection by accessing Firestore
    const db = getDb();
    await db.collection('_health').limit(1).get();
    
    logger.info('Firebase connection successful');
    return true;
  } catch (error) {
    logger.error('Firebase connection failed:', error);
    throw error;
  }
};

/**
 * Disconnect from Firebase
 */
const disconnect = async () => {
  try {
    if (initialized) {
      await admin.app().delete();
      initialized = false;
      db = null;
      auth = null;
      logger.info('Firebase disconnected');
    }
  } catch (error) {
    logger.error('Firebase disconnect error:', error);
    throw error;
  }
};

module.exports = {
  initializeFirebase,
  getDb,
  getAuth,
  query,
  connect,
  disconnect,
  admin,
  // Export for compatibility
  isMock: false,
  // Timestamp helpers
  FieldValue: admin.firestore.FieldValue,
  Timestamp: admin.firestore.Timestamp
};
