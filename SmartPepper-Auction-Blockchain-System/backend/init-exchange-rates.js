require('dotenv').config();
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } else if (process.env.FIREBASE_PROJECT_ID) {
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID
    });
  } else {
    console.error('❌ Firebase configuration not found in .env');
    console.log('Set either FIREBASE_SERVICE_ACCOUNT or FIREBASE_PROJECT_ID');
    process.exit(1);
  }
}

const db = admin.firestore();

async function initializeExchangeRates() {
  try {
    console.log('🔧 Initializing exchange rates in Firebase...\n');
    
    // Define exchange rates (approximate as of 2026)
    // ETH ≈ $3,125, LKR ≈ 322.58 per USD
    const rates = [
      {
        id: 'LKR_ETH',
        from_currency: 'LKR',
        to_currency: 'ETH',
        rate: 0.0000031,
        is_active: true,
        description: 'Sri Lankan Rupee to Ethereum'
      },
      {
        id: 'ETH_LKR',
        from_currency: 'ETH',
        to_currency: 'LKR',
        rate: 322580.65,
        is_active: true,
        description: 'Ethereum to Sri Lankan Rupee'
      },
      {
        id: 'USD_ETH',
        from_currency: 'USD',
        to_currency: 'ETH',
        rate: 0.00032,
        is_active: true,
        description: 'US Dollar to Ethereum'
      },
      {
        id: 'ETH_USD',
        from_currency: 'ETH',
        to_currency: 'USD',
        rate: 3125.00,
        is_active: true,
        description: 'Ethereum to US Dollar'
      },
      {
        id: 'LKR_USD',
        from_currency: 'LKR',
        to_currency: 'USD',
        rate: 0.0031,
        is_active: true,
        description: 'Sri Lankan Rupee to US Dollar'
      },
      {
        id: 'USD_LKR',
        from_currency: 'USD',
        to_currency: 'LKR',
        rate: 322.58,
        is_active: true,
        description: 'US Dollar to Sri Lankan Rupee'
      }
    ];

    // Create exchange_rates collection and add rates
    const batch = db.batch();
    
    for (const rate of rates) {
      const { id, ...data } = rate;
      const ref = db.collection('exchange_rates').doc(id);
      batch.set(ref, {
        ...data,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`✅ ${rate.from_currency} → ${rate.to_currency}: ${rate.rate}`);
    }

    await batch.commit();
    
    console.log('\n✅ Exchange rates initialized successfully!');
    console.log('\nExample conversions:');
    console.log('- 100,000 LKR = 0.31 ETH');
    console.log('- 0.32 ETH = 103,225 LKR');
    console.log('- 1,000 USD = 0.32 ETH');
    console.log('- 1 ETH = $3,125');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error initializing exchange rates:', error);
    process.exit(1);
  }
}

initializeExchangeRates();
