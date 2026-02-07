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

async function enableUser(email) {
  try {
    console.log(`Looking for user: ${email}`);
    
    // Find user by email
    const userSnapshot = await db.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();
    
    if (userSnapshot.empty) {
      console.error('❌ User not found');
      process.exit(1);
    }
    
    const userDoc = userSnapshot.docs[0];
    const userData = userDoc.data();
    
    console.log('\nCurrent user data:');
    console.log('- Name:', userData.name);
    console.log('- Email:', userData.email);
    console.log('- Role:', userData.role);
    console.log('- is_active:', userData.is_active);
    console.log('- Phone:', userData.phone);
    console.log('- Wallet:', userData.wallet_address);
    
    // Enable the user
    await userDoc.ref.update({
      is_active: true,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('\n✅ User account enabled successfully!');
    
    // Verify the update
    const updatedDoc = await userDoc.ref.get();
    const updatedData = updatedDoc.data();
    console.log('\nUpdated is_active:', updatedData.is_active);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error enabling user:', error);
    process.exit(1);
  }
}

// Get email from command line argument
const email = process.argv[2];

if (!email) {
  console.error('Usage: node enable-user.js <email>');
  console.error('Example: node enable-user.js sachinf@gmail.com');
  process.exit(1);
}

enableUser(email);
