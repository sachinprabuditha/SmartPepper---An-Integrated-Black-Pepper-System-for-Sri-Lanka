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

async function updateGovernanceWithExchangeRates() {
  try {
    console.log('🔧 Updating governance settings with exchange rates...\n');
    
    // Get existing settings
    const settingsSnapshot = await db.collection('governance_settings').limit(1).get();
    
    if (settingsSnapshot.empty) {
      console.error('❌ No governance settings found. Run init-governance-settings.js first.');
      process.exit(1);
    }
    
    const settingsDoc = settingsSnapshot.docs[0];
    const currentData = settingsDoc.data();
    
    console.log('Current settings:');
    console.log('- Min Reserve Price:', currentData.min_reserve_price);
    console.log('- Max Reserve Price:', currentData.max_reserve_price);
    console.log('- LKR to ETH Rate:', currentData.lkr_to_eth_rate || 'Not set');
    console.log('- USD to ETH Rate:', currentData.usd_to_eth_rate || 'Not set');
    
    // Update with exchange rates
    const updateData = {
      // Exchange rates (approximate as of 2026)
      // 1 LKR ≈ 0.0000031 ETH (assuming ~320 LKR per USD, ~3100 USD per ETH)
      lkr_to_eth_rate: 0.0000031,
      // 1 USD ≈ 0.00032 ETH (assuming ~3100 USD per ETH)
      usd_to_eth_rate: 0.00032,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: 'system'
    };
    
    await settingsDoc.ref.update(updateData);
    
    console.log('\n✅ Exchange rates added successfully!');
    console.log('- LKR to ETH: 1 LKR = 0.0000031 ETH');
    console.log('- USD to ETH: 1 USD = 0.00032 ETH');
    console.log('\nExample conversions:');
    console.log('- 100,000 LKR = 0.31 ETH');
    console.log('- 1,000 USD = 0.32 ETH');
    console.log('- 10,000 USD = 3.2 ETH');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error updating governance settings:', error);
    process.exit(1);
  }
}

updateGovernanceWithExchangeRates();
