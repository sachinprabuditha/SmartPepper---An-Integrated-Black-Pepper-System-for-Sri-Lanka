/**
 * PostgreSQL to Firebase Migration Script
 * 
 * This script exports all data from PostgreSQL and imports it into Firebase Firestore
 */

require('dotenv').config();
const { Pool } = require('pg');
const admin = require('firebase-admin');

// PostgreSQL connection
const pgPool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'smartpepper',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
});

// Initialize Firebase
let firestore;
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: process.env.FIREBASE_DATABASE_URL
    });
  } else if (process.env.FIREBASE_PROJECT_ID) {
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID,
      databaseURL: process.env.FIREBASE_DATABASE_URL
    });
  }
  firestore = admin.firestore();
  console.log('✅ Firebase initialized');
} catch (error) {
  console.error('❌ Failed to initialize Firebase:', error.message);
  process.exit(1);
}

// Tables to migrate and their Firebase collection names
const TABLES_TO_MIGRATE = [
  { table: 'users', collection: 'users' },
  { table: 'pepper_lots', collection: 'pepper_lots' },
  { table: 'auctions', collection: 'auctions' },
  { table: 'bids', collection: 'bids' },
  { table: 'processing_stages', collection: 'processing_stages' },
  { table: 'certifications', collection: 'certifications' },
  { table: 'compliance_rules', collection: 'compliance_rules' },
  { table: 'compliance_checks', collection: 'compliance_checks' },
  { table: 'escrow_accounts', collection: 'escrow_accounts' },
  { table: 'escrow_transactions', collection: 'escrow_transactions' },
  { table: 'governance_proposals', collection: 'governance_proposals' },
  { table: 'governance_votes', collection: 'governance_votes' },
];

/**
 * Convert PostgreSQL timestamp to Firebase timestamp
 */
function convertTimestamp(value) {
  if (!value) return null;
  if (value instanceof Date) {
    return admin.firestore.Timestamp.fromDate(value);
  }
  return admin.firestore.Timestamp.fromDate(new Date(value));
}

/**
 * Clean and prepare data for Firebase
 */
function prepareDataForFirebase(row) {
  const cleanedRow = {};
  
  for (const [key, value] of Object.entries(row)) {
    // Skip null values
    if (value === null || value === undefined) {
      continue;
    }
    
    // Convert timestamps
    if (key.includes('_at') || key.includes('_time') || key.includes('date')) {
      cleanedRow[key] = convertTimestamp(value);
    }
    // Keep other values as is
    else {
      cleanedRow[key] = value;
    }
  }
  
  return cleanedRow;
}

/**
 * Export data from PostgreSQL table
 */
async function exportFromPostgres(tableName) {
  try {
    console.log(`\n📤 Exporting from table: ${tableName}`);
    const result = await pgPool.query(`SELECT * FROM ${tableName}`);
    console.log(`   Found ${result.rows.length} records`);
    return result.rows;
  } catch (error) {
    if (error.code === '42P01') {
      console.log(`   ⚠️  Table ${tableName} does not exist, skipping...`);
      return [];
    }
    throw error;
  }
}

/**
 * Import data to Firebase collection
 */
async function importToFirebase(collectionName, data) {
  if (data.length === 0) {
    console.log(`   ⏭️  No data to import`);
    return;
  }

  console.log(`📥 Importing to collection: ${collectionName}`);
  
  const batch = firestore.batch();
  let count = 0;
  let batchCount = 0;
  const BATCH_SIZE = 500; // Firestore batch limit

  for (const row of data) {
    const docData = prepareDataForFirebase(row);
    
    // Use the original ID if available, otherwise auto-generate
    let docRef;
    if (row.id) {
      docRef = firestore.collection(collectionName).doc(String(row.id));
      // Remove id from data since it's used as document ID
      delete docData.id;
    } else {
      docRef = firestore.collection(collectionName).doc();
    }
    
    batch.set(docRef, docData);
    count++;
    batchCount++;

    // Commit batch when reaching limit
    if (batchCount >= BATCH_SIZE) {
      await batch.commit();
      console.log(`   ✅ Batch committed: ${count}/${data.length} records`);
      batchCount = 0;
    }
  }

  // Commit remaining records
  if (batchCount > 0) {
    await batch.commit();
  }

  console.log(`   ✅ Imported ${count} records to ${collectionName}`);
}

/**
 * Main migration function
 */
async function migrate() {
  console.log('🚀 Starting PostgreSQL to Firebase migration...\n');
  console.log('⚠️  IMPORTANT: This will ADD data to Firebase, not replace existing data');
  console.log('⚠️  Make sure to backup your Firebase database before proceeding\n');

  const stats = {
    total: 0,
    successful: 0,
    failed: 0,
    skipped: 0
  };

  try {
    // Test PostgreSQL connection
    await pgPool.query('SELECT NOW()');
    console.log('✅ PostgreSQL connected\n');

    // Migrate each table
    for (const { table, collection } of TABLES_TO_MIGRATE) {
      stats.total++;
      try {
        const data = await exportFromPostgres(table);
        
        if (data.length === 0) {
          stats.skipped++;
          continue;
        }

        await importToFirebase(collection, data);
        stats.successful++;
        
      } catch (error) {
        stats.failed++;
        console.error(`❌ Error migrating ${table}:`, error.message);
      }
    }

    // Print summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 MIGRATION SUMMARY');
    console.log('='.repeat(60));
    console.log(`Total tables processed: ${stats.total}`);
    console.log(`✅ Successful: ${stats.successful}`);
    console.log(`⏭️  Skipped (empty): ${stats.skipped}`);
    console.log(`❌ Failed: ${stats.failed}`);
    console.log('='.repeat(60));

    if (stats.failed === 0) {
      console.log('\n🎉 Migration completed successfully!');
      console.log('\n📝 Next steps:');
      console.log('1. Verify data in Firebase Console');
      console.log('2. Update your route files to use Firebase queries');
      console.log('3. Test your application thoroughly');
      console.log('4. Once confirmed working, you can safely remove PostgreSQL');
    } else {
      console.log('\n⚠️  Migration completed with errors. Please review and retry failed tables.');
    }

  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  } finally {
    // Close connections
    await pgPool.end();
    console.log('\n✅ Connections closed');
  }
}

// Add confirmation prompt
console.log('╔════════════════════════════════════════════════════════════╗');
console.log('║  PostgreSQL → Firebase Migration Tool                     ║');
console.log('╚════════════════════════════════════════════════════════════╝');
console.log('');
console.log('This will migrate all data from PostgreSQL to Firebase.');
console.log('');
console.log('Press Ctrl+C to cancel, or wait 5 seconds to continue...');
console.log('');

setTimeout(() => {
  migrate().then(() => {
    process.exit(0);
  }).catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}, 5000);
