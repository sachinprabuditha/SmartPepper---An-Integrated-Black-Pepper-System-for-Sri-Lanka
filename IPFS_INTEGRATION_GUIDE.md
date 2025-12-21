# 📦 IPFS Integration Guide

## Overview

SmartPepper now integrates **IPFS (InterPlanetary File System)** for decentralized, tamper-proof certificate document storage. This ensures regulatory documents (organic certificates, fumigation certificates, lab tests) are permanently stored and verifiable.

---

## 🎯 Why IPFS?

**Traditional Cloud Storage Issues:**

- ❌ Centralized (single point of failure)
- ❌ Can be modified or deleted by provider
- ❌ Monthly storage fees
- ❌ Requires trust in third party

**IPFS Advantages:**

- ✅ Decentralized (files distributed across network)
- ✅ Content-addressed (same file = same hash, immutable)
- ✅ Permanent storage (pinned files persist indefinitely)
- ✅ Verifiable (hash proves file integrity)
- ✅ Blockchain-compatible (store IPFS CID on-chain)

---

## 🔧 Setup Instructions

### Option 1: Public IPFS Gateway (Infura - Recommended for Production)

**1. Create Infura Account**

- Go to: https://infura.io/
- Sign up for free account
- Navigate to IPFS section
- Create new IPFS project

**2. Get API Credentials**

- Copy your Project ID
- Copy your Project Secret (API Key Secret)

**3. Configure Environment Variables**

Create/update `web/.env.local`:

```env
# IPFS Configuration (Infura)
NEXT_PUBLIC_INFURA_PROJECT_ID=your_project_id_here
NEXT_PUBLIC_INFURA_PROJECT_SECRET=your_project_secret_here

# Generate auth token: base64(projectId:projectSecret)
# Example in PowerShell:
# $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("projectId:projectSecret"))
# echo "Basic $auth"
NEXT_PUBLIC_INFURA_IPFS_AUTH=Basic YOUR_BASE64_AUTH_TOKEN_HERE
```

**4. Test Connection**

```powershell
cd web
npm run dev
```

Open http://localhost:3001/harvest/register and upload a test certificate.

---

### Option 2: Local IPFS Node (Development)

**1. Install IPFS Desktop**

```powershell
# Using Chocolatey
choco install ipfs-desktop

# Or download from:
# https://docs.ipfs.tech/install/ipfs-desktop/
```

**2. Start IPFS Daemon**

- Open IPFS Desktop app
- Wait for "Connected to IPFS" status
- Default API endpoint: http://localhost:5001

**3. Configure for Local Node**

Edit `web/src/lib/ipfs.ts`:

```typescript
const IPFS_CONFIG = {
  // Local IPFS node
  host: "localhost",
  port: 5001,
  protocol: "http",

  headers: {
    // No auth needed for local node
  },
};
```

**4. Enable CORS (Required for browser access)**

```powershell
# In PowerShell
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["http://localhost:3001", "http://localhost:3000"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'

# Restart IPFS Desktop
```

---

### Option 3: Pinata (Alternative Cloud IPFS)

**1. Create Pinata Account**

- Go to: https://pinata.cloud/
- Sign up (free tier: 1GB storage)

**2. Get API Keys**

- Navigate to API Keys section
- Create new key with upload permissions
- Copy JWT token

**3. Configure**

```typescript
// web/src/lib/ipfs.ts
const IPFS_CONFIG = {
  host: "api.pinata.cloud",
  port: 443,
  protocol: "https",
  headers: {
    authorization: `Bearer ${process.env.NEXT_PUBLIC_PINATA_JWT}`,
  },
};
```

**Environment:**

```env
# web/.env.local
NEXT_PUBLIC_PINATA_JWT=your_jwt_token_here
```

---

## 📋 Usage in Application

### 1. Upload Certificate with Document

```typescript
import { uploadToIPFS, generateDocumentHash } from "@/lib/ipfs";

// In your form handler
const file = fileInput.files[0]; // User-selected PDF/image

// Generate hash for blockchain
const documentHash = await generateDocumentHash(file);
// Returns: 0xabc123... (SHA-256 hash)

// Upload to IPFS
const { cid, ipfsUrl, gatewayUrl } = await uploadToIPFS(file);
// cid: "QmX4x7..."
// ipfsUrl: "ipfs://QmX4x7..."
// gatewayUrl: "https://ipfs.io/ipfs/QmX4x7..."

// Save to database
await fetch("/api/certifications", {
  method: "POST",
  body: JSON.stringify({
    documentHash, // For smart contract
    ipfsUrl, // For database
    // ... other fields
  }),
});
```

### 2. Retrieve/View Certificate

**Via Gateway URL:**

```typescript
// Stored in database
const ipfsCid = "QmX4x7...";

// Multiple gateway options (redundancy)
const urls = [
  `https://ipfs.io/ipfs/${ipfsCid}`, // Public gateway
  `https://cloudflare-ipfs.com/ipfs/${ipfsCid}`, // Cloudflare
  `https://dweb.link/ipfs/${ipfsCid}`, // Protocol Labs
];

// Display in browser
<a href={urls[0]} target="_blank">
  View Certificate
</a>;
```

**Direct Download:**

```typescript
import { retrieveFromIPFS } from "@/lib/ipfs";

const blob = await retrieveFromIPFS(ipfsCid);
const url = URL.createObjectURL(blob);

// Trigger download
const a = document.createElement("a");
a.href = url;
a.download = "certificate.pdf";
a.click();
```

---

## 🧪 Testing IPFS Integration

### Test 1: Upload Certificate

```powershell
cd web
npm run dev
```

1. Navigate to http://localhost:3001/harvest/register
2. Complete Steps 1-2 (Harvest Info, Processing Stages)
3. In Step 3 (Certificates):
   - Select certificate type
   - Fill in certificate details
   - **Click "Choose File"** and select PDF/image
   - Click "Add Certificate"
4. Verify success message with IPFS CID
5. Click IPFS link to view document in browser

### Test 2: Verify Document Hash

```javascript
// In browser console (F12)
const cert = {
  documentHash: "0xabc123...", // From database
  ipfsCid: "QmX4x7...", // From IPFS
};

// Download file from IPFS
const response = await fetch(`https://ipfs.io/ipfs/${cert.ipfsCid}`);
const blob = await response.blob();

// Calculate hash locally
const buffer = await blob.arrayBuffer();
const hashBuffer = await crypto.subtle.digest("SHA-256", buffer);
const hashArray = Array.from(new Uint8Array(hashBuffer));
const calculatedHash =
  "0x" + hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

// Compare
console.log("Database hash:", cert.documentHash);
console.log("Calculated hash:", calculatedHash);
console.log("Match:", cert.documentHash === calculatedHash);
// Should print: true
```

### Test 3: Check IPFS Status

```typescript
import { checkIPFSStatus } from "@/lib/ipfs";

const status = await checkIPFSStatus();
console.log(status);
// {
//   connected: true,
//   peerId: "QmYourNodeId...",
//   version: "0.16.0"
// }
```

---

## 📊 Database Schema Updates

### certifications Table

```sql
-- Already included in migrate.js
CREATE TABLE certifications (
  id UUID PRIMARY KEY,
  lot_id VARCHAR(50) REFERENCES pepper_lots(lot_id),
  cert_type VARCHAR(50) CHECK (cert_type IN (
    'organic', 'fumigation', 'export', 'quality',
    'phytosanitary', 'pesticide_test', 'halal', 'origin'
  )),
  cert_number VARCHAR(100) NOT NULL,
  issuer VARCHAR(255) NOT NULL,
  issue_date DATE NOT NULL,
  expiry_date DATE NOT NULL,
  document_hash VARCHAR(66),    -- SHA-256 hash (0x + 64 chars)
  ipfs_url TEXT,               -- ipfs://Qm... or ipfs://baf...
  is_valid BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Query Examples:**

```sql
-- Get all certificates with IPFS documents
SELECT
  cert_number,
  cert_type,
  ipfs_url,
  document_hash
FROM certifications
WHERE ipfs_url IS NOT NULL;

-- Verify document integrity
SELECT
  lot_id,
  cert_number,
  CASE
    WHEN document_hash IS NOT NULL THEN 'Verifiable'
    ELSE 'No hash stored'
  END as integrity_status
FROM certifications;
```

---

## 🔒 Security Considerations

### 1. Document Validation

```typescript
// Enforced in ipfs.ts
validateFile(file, 10); // Max 10MB

// Allowed types:
// - application/pdf
// - image/jpeg
// - image/png
// - image/webp
```

### 2. Hash Verification

- **SHA-256** used for cryptographic integrity
- Store hash **on-chain** (smart contract) for immutability
- Anyone can verify: `hash(IPFS_file) === blockchain_hash`

### 3. Privacy Concerns

**IPFS is PUBLIC by default:**

- Anyone with CID can access file
- Suitable for: public certificates, export licenses
- **NOT suitable for:** personal info, trade secrets

**Solution for Private Data:**

```typescript
// Encrypt before uploading
import { encrypt } from "@/lib/encryption";

const encrypted = await encrypt(fileBuffer, publicKey);
const { cid } = await uploadToIPFS(encrypted);
// Only holders of private key can decrypt
```

---

## 💰 Cost Analysis

### Infura IPFS Pricing (as of 2024)

- **Free tier:** 5GB storage, 100GB bandwidth/month
- **Growth tier:** $200/month - 250GB storage, 2TB bandwidth
- **Enterprise:** Custom pricing

**Estimated Costs for SmartPepper:**

- Avg certificate size: 500KB
- 1000 certificates/month: 500MB storage
- **Cost:** FREE (under 5GB limit)

### Pinata Pricing

- **Free:** 1GB storage
- **Picnic ($20/mo):** 50GB storage
- **Business ($1000/mo):** 1TB storage

### Local IPFS Node

- **Storage:** Your disk space
- **Bandwidth:** Your internet
- **Cost:** $0
- **Reliability:** Depends on uptime

**Recommendation:** Start with Infura free tier, upgrade as needed.

---

## 🚨 Troubleshooting

### Error: "Failed to upload to IPFS"

**Check 1: IPFS Connection**

```typescript
import { checkIPFSStatus } from "@/lib/ipfs";
const status = await checkIPFSStatus();
console.log(status.connected); // Should be true
```

**Check 2: Environment Variables**

```powershell
# Verify .env.local exists
cat web/.env.local

# Should show:
# NEXT_PUBLIC_INFURA_IPFS_AUTH=Basic ...
```

**Check 3: CORS (Local Node)**

```powershell
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
# Restart IPFS Desktop
```

---

### Error: "File too large"

```typescript
// Default limit: 10MB
validateFile(file, 10);

// Increase limit (not recommended):
validateFile(file, 20); // 20MB
```

**Better Solution:** Compress PDFs before upload

```powershell
# Using Ghostscript
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf original.pdf
```

---

### Error: "Invalid file type"

Allowed types in `ipfs.ts`:

- `application/pdf`
- `image/jpeg`
- `image/png`
- `image/webp`

Convert other formats before upload.

---

## 📈 Future Enhancements

### 1. IPFS Cluster (High Availability)

- Multiple IPFS nodes replicating data
- No single point of failure
- Automatic failover

### 2. Filecoin Integration

- Long-term storage deals
- Economic incentives for storage providers
- Guaranteed persistence

### 3. Encrypted Certificates

```typescript
// For sensitive documents
const encrypted = await encryptFile(file, publicKey);
await uploadToIPFS(encrypted);
// Only exporter with private key can view
```

### 4. Certificate NFTs

```solidity
// Smart contract stores IPFS hash
function mintCertificateNFT(
  string memory ipfsHash,
  bytes32 documentHash
) external returns (uint256 tokenId);
```

---

## 🎓 Learn More

**IPFS Documentation:**

- Official Docs: https://docs.ipfs.tech/
- IPFS Desktop: https://docs.ipfs.tech/install/ipfs-desktop/
- HTTP Client: https://github.com/ipfs/js-ipfs/tree/master/packages/ipfs-http-client

**Video Tutorials:**

- IPFS 101: https://www.youtube.com/watch?v=5Uj6uR3fp-U
- Web3 Storage Guide: https://www.youtube.com/watch?v=5HF3q8vO9s8

---

## ✅ Checklist

Before deploying to production:

- [ ] Infura account created and API keys configured
- [ ] Environment variables set in `web/.env.local`
- [ ] Test certificate upload with PDF
- [ ] Verify IPFS CID displays in UI
- [ ] Check gateway URL opens document
- [ ] Document hash matches calculated hash
- [ ] Database stores `ipfs_url` and `document_hash`
- [ ] Error handling tested (large files, wrong types)
- [ ] CORS configured (if using local node)
- [ ] Backup strategy planned (pin important CIDs)

---

**Status:** ✅ IPFS Integration Complete  
**Next Steps:** Test with real certificate documents, monitor storage costs

_Last Updated: December 4, 2025_
