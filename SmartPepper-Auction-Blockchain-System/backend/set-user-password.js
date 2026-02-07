require('dotenv').config();
const admin = require('firebase-admin');
const bcrypt = require('bcryptjs');

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

async function setUserPassword(email, password, role = 'farmer', phone = null) {
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
    console.log('- User Type:', userData.user_type);
    console.log('- Has password_hash:', !!userData.password_hash);
    console.log('- Phone:', userData.phone);
    console.log('- Wallet:', userData.wallet_address);
    console.log('- is_active:', userData.is_active);
    
    // Hash the new password
    console.log('\n🔐 Hashing password...');
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);
    
    // Prepare update data
    const updateData = {
      password_hash: passwordHash,
      is_active: true,
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    };
    
    // Add role if not present
    if (!userData.role) {
      updateData.role = role;
      console.log(`📝 Adding role: ${role}`);
    }
    
    // Add user_type if not present
    if (!userData.user_type) {
      const userTypeMap = {
        'admin': 'regulator',
        'exporter': 'exporter',
        'farmer': 'farmer'
      };
      updateData.user_type = userTypeMap[role] || 'farmer';
      console.log(`📝 Adding user_type: ${updateData.user_type}`);
    }
    
    // Add phone if provided and not present
    if (phone && !userData.phone) {
      updateData.phone = phone;
      console.log(`📝 Adding phone: ${phone}`);
    }
    
    // Update the user
    await userDoc.ref.update(updateData);
    
    console.log('\n✅ User account updated successfully!');
    console.log('   - Password hash set');
    console.log('   - Account enabled');
    if (updateData.role) console.log(`   - Role set to: ${updateData.role}`);
    if (updateData.user_type) console.log(`   - User type set to: ${updateData.user_type}`);
    if (updateData.phone) console.log(`   - Phone set to: ${updateData.phone}`);
    
    // Verify the update
    const updatedDoc = await userDoc.ref.get();
    const updatedData = updatedDoc.data();
    console.log('\nVerification:');
    console.log('- Has password_hash:', !!updatedData.password_hash);
    console.log('- is_active:', updatedData.is_active);
    console.log('- role:', updatedData.role);
    console.log('- user_type:', updatedData.user_type);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error updating user:', error);
    process.exit(1);
  }
}

// Get arguments from command line
const email = process.argv[2];
const password = process.argv[3];
const role = process.argv[4];
const phone = process.argv[5];

if (!email || !password) {
  console.error('Usage: node set-user-password.js <email> <password> [role] [phone]');
  console.error('Example: node set-user-password.js sachinf@gmail.com 123456 farmer +94771234567');
  console.error('\nRoles: farmer, exporter, admin');
  process.exit(1);
}

setUserPassword(email, password, role, phone);
