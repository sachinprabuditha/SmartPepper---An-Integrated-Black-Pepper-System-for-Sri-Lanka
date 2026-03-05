require('dotenv').config();
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
  console.error('❌ FIREBASE_SERVICE_ACCOUNT environment variable not set');
  process.exit(1);
}

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function initializeGovernanceSettings() {
  try {
    console.log('🔧 Initializing governance settings...\n');
    
    // Check if settings already exist
    const settingsSnapshot = await db.collection('governance_settings').get();
    
    if (!settingsSnapshot.empty) {
      console.log('⚠️  Governance settings already exist:');
      settingsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        console.log(`   - ${doc.id}: ${data.key || 'unnamed'}`);
      });
      
      const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
      });
      
      const answer = await new Promise(resolve => {
        readline.question('\nDo you want to overwrite existing settings? (yes/no): ', resolve);
      });
      readline.close();
      
      if (answer.toLowerCase() !== 'yes') {
        console.log('✅ Keeping existing settings.');
        process.exit(0);
      }
      
      // Delete existing settings
      console.log('\n🗑️  Deleting existing settings...');
      const batch = db.batch();
      settingsSnapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    }
    
    // Default governance settings
    const defaultSettings = {
      auction_duration: {
        key: 'auction_duration',
        value: 7,
        unit: 'days',
        description: 'Default duration for auctions',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: 'system'
      },
      min_bid_increment: {
        key: 'min_bid_increment',
        value: 100,
        unit: 'USD',
        description: 'Minimum bid increment amount',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: 'system'
      },
      min_lot_quantity: {
        key: 'min_lot_quantity',
        value: 10,
        unit: 'kg',
        description: 'Minimum quantity for a lot',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: 'system'
      },
      max_lot_quantity: {
        key: 'max_lot_quantity',
        value: 10000,
        unit: 'kg',
        description: 'Maximum quantity for a lot',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: 'system'
      },
      required_certificates: {
        key: 'required_certificates',
        value: 3,
        unit: 'count',
        description: 'Minimum number of certificates required',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: 'system'
      },
      escrow_fee_percentage: {
        key: 'escrow_fee_percentage',
        value: 2.5,
        unit: 'percent',
        description: 'Escrow service fee percentage',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: 'system'
      },
      compliance_validity_days: {
        key: 'compliance_validity_days',
        value: 90,
        unit: 'days',
        description: 'Validity period for compliance checks',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: 'system'
      }
    };
    
    // Create settings
    console.log('\n📝 Creating default governance settings...');
    const batch = db.batch();
    
    for (const [id, setting] of Object.entries(defaultSettings)) {
      const docRef = db.collection('governance_settings').doc(id);
      batch.set(docRef, setting);
      console.log(`   ✓ ${setting.key}: ${setting.value} ${setting.unit}`);
    }
    
    await batch.commit();
    
    console.log('\n✅ Governance settings initialized successfully!');
    console.log('\nSettings created:');
    console.log('- Auction Duration: 7 days');
    console.log('- Min Bid Increment: 100 USD');
    console.log('- Min Lot Quantity: 10 kg');
    console.log('- Max Lot Quantity: 10000 kg');
    console.log('- Required Certificates: 3');
    console.log('- Escrow Fee: 2.5%');
    console.log('- Compliance Validity: 90 days');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error initializing governance settings:', error);
    process.exit(1);
  }
}

initializeGovernanceSettings();
