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

async function createCompleteGovernanceSettings() {
  try {
    console.log('🔧 Creating complete governance settings document...\n');
    
    // Delete existing settings
    const existingSnapshot = await db.collection('governance_settings').get();
    if (!existingSnapshot.empty) {
      console.log('🗑️  Deleting existing settings...');
      const batch = db.batch();
      existingSnapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    }
    
    // Create comprehensive settings document
    const settingsData = {
      // Auction duration settings
      default_min_duration_hours: 24,
      default_max_duration_hours: 168, // 7 days
      allowed_durations: [24, 48, 72, 96, 168], // hours
      
      // Price settings
      min_reserve_price: 1000, // LKR or USD minimum
      max_reserve_price: 10000000, // LKR or USD maximum
      default_bid_increment: 5.0, // percentage
      
      // Exchange rates (approximate as of 2026)
      lkr_to_eth_rate: 0.0000031, // 1 LKR ≈ 0.0000031 ETH
      usd_to_eth_rate: 0.00032,   // 1 USD ≈ 0.00032 ETH (~3125 USD per ETH)
      
      // Approval settings
      requires_admin_approval: false,
      
      // Metadata
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: 'system',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };
    
    const docRef = await db.collection('governance_settings').add(settingsData);
    
    console.log('✅ Complete governance settings created successfully!\n');
    console.log('Settings:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('Auction Duration:');
    console.log('  - Min: 24 hours (1 day)');
    console.log('  - Max: 168 hours (7 days)');
    console.log('  - Allowed: 24h, 48h, 72h, 96h, 168h');
    console.log('\nPrice Settings:');
    console.log('  - Min Reserve: 1,000');
    console.log('  - Max Reserve: 10,000,000');
    console.log('  - Default Bid Increment: 5%');
    console.log('\nExchange Rates:');
    console.log('  - LKR to ETH: 0.0000031');
    console.log('  - USD to ETH: 0.00032');
    console.log('\nApproval:');
    console.log('  - Requires Admin Approval: No');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`\nDocument ID: ${docRef.id}`);
    
    console.log('\n💡 Example conversions:');
    console.log('  - 100,000 LKR = 0.31 ETH');
    console.log('  - 1,000 USD = 0.32 ETH');
    console.log('  - 10,000 USD = 3.20 ETH');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating governance settings:', error);
    process.exit(1);
  }
}

createCompleteGovernanceSettings();
