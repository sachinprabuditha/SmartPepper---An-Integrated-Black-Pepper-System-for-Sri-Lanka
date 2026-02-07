# Firebase Migration Guide

## Overview

This project has been migrated from PostgreSQL to Firebase Firestore. This guide will help you set up and understand the new database structure.

## Why Firebase?

- **Real-time capabilities**: Perfect for auction systems with live bidding
- **Scalability**: Auto-scales with your application
- **NoSQL flexibility**: Better suited for dynamic auction data
- **Built-in authentication**: Integrates seamlessly with Firebase Auth
- **Reduced maintenance**: No server management needed
- **Cost-effective**: Pay only for what you use

## Setup Instructions

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Name your project (e.g., "smartpepper-auction")
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Enable Firestore Database

1. In Firebase Console, navigate to **Build > Firestore Database**
2. Click "Create database"
3. Choose "Start in production mode" (recommended) or "test mode" for development
4. Select your database location (choose closest to your users)
5. Click "Enable"

### 3. Get Firebase Credentials

#### Option A: Service Account (Recommended for Production)

1. Go to **Project Settings** (gear icon) > **Service Accounts**
2. Click "Generate new private key"
3. Download the JSON file
4. Copy the entire JSON content
5. Add to your `.env` file as a single line:
   ```
   FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"...","private_key_id":"..."}
   ```

#### Option B: Project ID (For Local Development)

1. Go to **Project Settings** (gear icon) > **General**
2. Copy your "Project ID"
3. Add to your `.env` file:
   ```
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_DATABASE_URL=https://your-project-id.firebaseio.com
   ```

### 4. Configure Environment Variables

Update your `backend/.env` file:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=smartpepper-auction
FIREBASE_DATABASE_URL=https://smartpepper-auction.firebaseio.com

# OR use service account JSON (one line)
# FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
```

### 5. Install Dependencies

```bash
cd backend
npm install
```

This will install:

- `firebase-admin` - Firebase Admin SDK for Node.js
- `firebase` - Firebase client SDK (if needed for client-side)

### 6. Set Up Firestore Security Rules

In Firebase Console, go to **Firestore Database > Rules** and set up your security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Pepper lots collection
    match /pepper_lots/{lotId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.token.role == 'farmer';
      allow update: if request.auth != null &&
        (request.auth.token.role == 'admin' ||
         resource.data.farmer_id == request.auth.uid);
      allow delete: if request.auth != null && request.auth.token.role == 'admin';
    }

    // Auctions collection
    match /auctions/{auctionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.token.role == 'admin';
      allow update: if request.auth != null &&
        (request.auth.token.role == 'admin' ||
         request.auth.token.role == 'buyer');
      allow delete: if request.auth != null && request.auth.token.role == 'admin';
    }

    // Bids collection
    match /bids/{bidId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
        request.auth.token.role == 'buyer' &&
        request.auth.uid == request.resource.data.bidder_id;
      allow update: if false; // Bids should not be updated
      allow delete: if false; // Bids should not be deleted
    }

    // Processing stages
    match /processing_stages/{stageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        (request.auth.token.role == 'farmer' ||
         request.auth.token.role == 'admin');
    }

    // Certifications
    match /certifications/{certId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.role == 'admin';
    }

    // Default deny all
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 7. Set Up Firebase Indexes

For optimal query performance, create these indexes in **Firestore > Indexes**:

1. **Auctions by status and start time**:

   - Collection: `auctions`
   - Fields: `status` (Ascending), `start_time` (Descending)

2. **Bids by auction and timestamp**:

   - Collection: `bids`
   - Fields: `auction_id` (Ascending), `timestamp` (Descending)

3. **Lots by farmer and created date**:
   - Collection: `pepper_lots`
   - Fields: `farmer_id` (Ascending), `created_at` (Descending)

## Data Structure

### Collections Overview

Firebase uses collections instead of tables. Here's the mapping:

| PostgreSQL Table  | Firebase Collection |
| ----------------- | ------------------- |
| users             | users               |
| pepper_lots       | pepper_lots         |
| auctions          | auctions            |
| bids              | bids                |
| processing_stages | processing_stages   |
| certifications    | certifications      |
| compliance_rules  | compliance_rules    |
| compliance_checks | compliance_checks   |
| escrow_accounts   | escrow_accounts     |

### Document Structure Examples

#### Users Collection

```javascript
{
  id: "auto-generated-id",
  wallet_address: "0x1234...",
  email: "farmer@example.com",
  role: "farmer",
  created_at: Timestamp,
  updated_at: Timestamp
}
```

#### Pepper Lots Collection

```javascript
{
  id: "auto-generated-id",
  lot_id: "LOT-2024-001",
  farmer_id: "user-id",
  quantity: 1000,
  variety: "Malabar",
  quality_grade: "A",
  status: "available",
  created_at: Timestamp,
  updated_at: Timestamp
}
```

#### Auctions Collection

```javascript
{
  id: "auto-generated-id",
  auction_id: "AUC-2024-001",
  lot_id: "lot-id",
  start_price: 5000,
  current_price: 5500,
  status: "active",
  start_time: Timestamp,
  end_time: Timestamp,
  created_at: Timestamp,
  updated_at: Timestamp
}
```

## Migration from PostgreSQL

### Exporting Data from PostgreSQL

If you have existing data in PostgreSQL, export it first:

```bash
# Export to JSON
pg_dump -U postgres -d smartpepper -t users --column-inserts > users.sql
# Convert to JSON using a tool or script
```

### Importing Data to Firestore

Use the Firebase Admin SDK to import data:

```javascript
const admin = require("firebase-admin");
const fs = require("fs");

// Read your exported data
const data = JSON.parse(fs.readFileSync("data.json", "utf8"));

// Import to Firestore
const db = admin.firestore();
const batch = db.batch();

data.users.forEach((user) => {
  const docRef = db.collection("users").doc();
  batch.set(docRef, user);
});

await batch.commit();
```

## Code Changes Required

### Before (PostgreSQL)

```javascript
const result = await db.query("SELECT * FROM users WHERE email = $1", [email]);
const user = result.rows[0];
```

### After (Firebase)

```javascript
const db = require("./db/database").getDb();
const snapshot = await db
  .collection("users")
  .where("email", "==", email)
  .limit(1)
  .get();
const user = snapshot.docs[0]?.data();
```

## Helper Functions

The new `firebase.js` module provides helper functions:

```javascript
const { query } = require("./db/firebase");

// Select documents
const result = await query.select("users", {
  where: [["email", "==", "user@example.com"]],
  limit: 1,
});

// Insert document
await query.insert("users", {
  email: "user@example.com",
  role: "farmer",
});

// Update document
await query.update("users", userId, {
  status: "active",
});

// Delete document
await query.delete("users", userId);
```

## Running the Application

```bash
cd backend
npm start
```

The application will automatically detect Firebase configuration and use Firestore.

## Testing

1. Start your application: `npm start`
2. Check logs for: "Database: Using Firebase Firestore"
3. Test API endpoints to ensure they work correctly
4. Monitor Firestore Console for real-time data changes

## Troubleshooting

### Error: "Firebase configuration missing"

- Ensure `FIREBASE_PROJECT_ID` or `FIREBASE_SERVICE_ACCOUNT` is set in `.env`
- Check that the `.env` file is in the `backend` directory

### Error: "Permission denied"

- Review Firestore Security Rules
- Ensure authenticated requests include proper auth tokens
- Check user roles and permissions

### Error: "Index required"

- Firebase will suggest the exact index needed
- Click the provided link to create the index automatically
- Or manually create in Firestore Console > Indexes

### Performance Issues

- Create appropriate indexes for frequently queried fields
- Use pagination for large result sets
- Implement caching with Redis where appropriate

## Best Practices

1. **Use subcollections** for nested data (e.g., bids under auctions)
2. **Implement pagination** using `startAfter()` and `limit()`
3. **Use batch writes** for multiple document updates
4. **Denormalize data** where appropriate for faster reads
5. **Monitor usage** in Firebase Console to optimize costs
6. **Use transactions** for atomic operations
7. **Implement retry logic** for write operations

## Cost Optimization

- Use indexes wisely (each index costs storage)
- Implement pagination to reduce document reads
- Cache frequently accessed data with Redis
- Use Firebase Analytics to monitor usage patterns
- Consider using Firebase Spark (free) tier for development

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Data Model](https://firebase.google.com/docs/firestore/data-model)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)

## Support

For issues or questions:

1. Check Firebase Console for error logs
2. Review application logs in `backend/logs/`
3. Consult Firebase documentation
4. Contact the development team

---

**Note**: Remember to update your mobile and web applications to use Firebase SDK as well for direct client access to Firestore.
