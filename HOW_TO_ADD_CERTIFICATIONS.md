# 📋 Adding Real Certifications and Running Compliance Checks

This guide explains how to add real certification data and run compliance checks from both the mobile app and web dashboard.

## 🚀 Quick Start

### Option 1: Using Mobile App (Farmer)

1. **Open Lot Details**

   - Navigate to "My Lots"
   - Select any lot
   - Scroll to "Certifications & Compliance" section

2. **Add Certificate**

   - Click **"Add Certificate"** button
   - Fill in the form:
     - Select certificate type (Organic, Fumigation, Quality, etc.)
     - Enter certificate number (e.g., ORG-2025-001)
     - Enter issuing authority
     - Select issue date and expiry date
   - Click **"Add Certification"**
   - ✅ Certificate saved!

3. **Run Compliance Check**
   - Click **"Check Compliance"** button
   - Select destination market:
     - European Union (EU)
     - United States (FDA)
     - Middle East
   - Wait for results (2-5 seconds)
   - View summary: Total checks, Passed, Failed
   - Click **"View Details"** to see full traceability

### Option 2: Using Web Dashboard (Admin)

1. **Import the Component**
   Add this to your admin lot details page (`web/src/app/dashboard/admin/lots/[lotId]/page.tsx`):

   ```typescript
   import CertificationManagement from "@/components/CertificationManagement";
   ```

2. **Add the Component**
   Place it in your page JSX before the lot details section:

   ```tsx
   <CertificationManagement
     lotId={lot.lot_id}
     onRefresh={() => fetchLotDetails()}
   />
   ```

3. **Use the Features**
   - Click **"Add Certificate"** → Fill form → Submit
   - Click **"Run Compliance Check"** → Select market → View results

### Option 3: Using PowerShell Script

For bulk testing or automation:

```powershell
# Add certifications for a specific lot
.\add-test-traceability-data.ps1 -LotId "LOT-1766820145306"
```

This automatically adds:

- 3 sample certificates (organic, fumigation, quality)
- Runs EU compliance check
- Verifies the data was added

---

## 📱 Mobile App Implementation Details

### Files Created/Modified:

1. **`mobile/lib/screens/farmer/add_certification_screen.dart`** (NEW)

   - Full-screen form for adding certifications
   - 8 certificate types supported
   - Date pickers for issue/expiry dates
   - Form validation
   - API integration

2. **`mobile/lib/screens/farmer/lot_details_screen.dart`** (MODIFIED)
   - Added `_buildCertificationManagementCard()` widget
   - Added "Add Certificate" button → Opens AddCertificationScreen
   - Added "Check Compliance" button → Shows market selection dialog
   - Added `_runComplianceCheck()` method with loading states
   - Shows results summary dialog with "View Details" button

### Features:

- ✅ Add certificates directly from lot details
- ✅ Run compliance checks with market selection
- ✅ View results summary
- ✅ Navigate to full traceability screen
- ✅ Refresh prompt after adding certificates
- ✅ Loading indicators during API calls
- ✅ Error handling with user-friendly messages

---

## 🌐 Web Dashboard Implementation Details

### Files Created:

1. **`web/src/components/AddCertificationModal.tsx`**

   - Modal dialog for adding certifications
   - Same 8 certificate types as mobile
   - Date inputs with validation
   - Responsive design
   - API integration

2. **`web/src/components/CertificationManagement.tsx`**
   - Reusable component for any admin page
   - Two action buttons: Add Certificate + Run Compliance
   - Handles modal display
   - Shows loading states
   - Calls parent refresh callback

### How to Integrate:

```typescript
// In your admin lot details page
import CertificationManagement from "@/components/CertificationManagement";

// In your component JSX
<CertificationManagement
  lotId={params.lotId}
  onRefresh={() => fetchLotDetails()}
/>;
```

---

## 🔍 What Data Gets Created

### Certifications Table:

```sql
INSERT INTO certifications (
  lot_id,
  cert_type,        -- organic, fumigation, quality, etc.
  cert_number,      -- ORG-2025-001
  issuer,           -- Sri Lanka Organic Certification
  issue_date,       -- 2025-01-15
  expiry_date,      -- 2026-01-15
  is_valid          -- true
)
```

### Compliance Checks Table:

```sql
INSERT INTO compliance_checks (
  lot_id,
  rule_name,        -- e.g., "EU Organic Certification Required"
  rule_type,        -- certification, quality, packaging
  passed,           -- true/false
  details,          -- JSON with check details
  checked_at        -- timestamp
)
```

For EU market, creates 7 compliance checks:

1. EU Organic Certification Required
2. Fumigation Certificate Required
3. EU Quality Standards
4. Proper Packaging Requirements
5. Accurate Labeling
6. Certificate of Origin
7. Traceability Documentation

---

## 🎯 User Flow Examples

### Scenario 1: Farmer Adding Organic Certificate

1. Farmer logs into mobile app
2. Navigates to "My Lots" → Selects lot "LOT-1766820145306"
3. Scrolls to "Certifications & Compliance" card
4. Taps **"Add Certificate"**
5. Form opens:
   - Type: Organic Certification
   - Number: ORG-SL-2025-001
   - Issuer: Sri Lanka Organic Certification Board
   - Issue: 2025-01-15
   - Expiry: 2026-01-15
6. Taps **"Add Certification"**
7. ✅ Success message appears
8. Returns to lot details (prompted to refresh)

### Scenario 2: Admin Running Compliance Check

1. Admin opens web dashboard
2. Goes to "Lot Management" → Clicks lot
3. Sees "Certifications & Compliance" section
4. Clicks **"Run Compliance Check"**
5. Popup asks: "Select destination market"
6. Enters "1" for EU
7. Loading spinner shows "Checking..."
8. Alert shows:

   ```
   Compliance Passed ✓

   Total Checks: 7
   Passed: 5
   Failed: 2

   View full details in the traceability page.
   ```

9. Clicks "OK" → Data is now in database
10. Clicks **"View Full Traceability"** to see all 7 check results

### Scenario 3: Viewing Traceability After Adding Data

1. User clicks **"Full Traceability"** button (mobile) or **"View Full Traceability"** (web)
2. Traceability screen opens with 5 tabs
3. **Certificates Tab**: Shows all added certificates (3 cards)
   - Each card shows: Type, Number, Issuer, Status, Dates
4. **Compliance Tab**: Shows all compliance checks (7 cards)
   - Each card shows: Rule name, Type, Pass/Fail status, Details
5. **Current Status**: Shows "Compliance Status: partial" (5 passed, 2 failed)

---

## 🧪 Testing Guide

### Test Case 1: Add Certificate via Mobile

```
Steps:
1. Open mobile app → My Lots → Select any lot
2. Tap "Add Certificate"
3. Fill form with test data
4. Submit

Expected:
✅ Success message appears
✅ Certificate saved to database
✅ Can view in traceability screen
```

### Test Case 2: Run Compliance Check via Web

```
Steps:
1. Open admin dashboard
2. Add <CertificationManagement> component to lot page
3. Click "Run Compliance Check"
4. Select "EU" market

Expected:
✅ Loading indicator shows
✅ Results alert appears with counts
✅ 7 compliance checks created in database
✅ Can view in traceability screen
```

### Test Case 3: Verify Traceability Display

```
Steps:
1. After adding 3 certificates and running compliance
2. Click "View Full Traceability"
3. Check Certificates tab
4. Check Compliance tab

Expected:
✅ Certificates tab shows 3 cards (not empty)
✅ Compliance tab shows 7 cards (not empty)
✅ Current Status shows compliance_status
```

---

## 🔧 API Endpoints Used

### POST /api/certifications

```json
{
  "lotId": "LOT-1766820145306",
  "certType": "organic",
  "certNumber": "ORG-2025-001",
  "issuer": "Sri Lanka Organic Certification",
  "issueDate": "2025-01-15",
  "expiryDate": "2026-01-15"
}
```

### POST /api/compliance/check/:lotId

```json
{
  "destination": "EU"
}
```

Response:

```json
{
  "success": true,
  "complianceStatus": "partial",
  "passedCount": 5,
  "failedCount": 2,
  "results": [...]
}
```

### GET /api/traceability/:lotId

Returns complete traceability including:

- `certifications[]` - All certificates
- `compliance_checks[]` - All compliance checks
- `current_status.compliance_status` - Overall status

---

## ✅ Verification Checklist

After implementation, verify:

- [ ] Mobile "Add Certificate" button appears in lot details
- [ ] Clicking button opens form screen
- [ ] Form submits and shows success message
- [ ] Mobile "Check Compliance" button works
- [ ] Compliance check shows market selection
- [ ] Compliance results dialog appears
- [ ] Web component can be imported
- [ ] Web "Add Certificate" opens modal
- [ ] Web "Run Compliance Check" works
- [ ] Certificates tab shows real data (not empty)
- [ ] Compliance tab shows real data (not empty)
- [ ] Current Status updates with compliance_status
- [ ] Can add multiple certificates
- [ ] Can run multiple compliance checks
- [ ] Data persists after refresh

---

## 🎓 Summary

**For Mobile Users (Farmers):**

- Use "Add Certificate" button in lot details
- Use "Check Compliance" button to validate lot
- View results in "Full Traceability" screen

**For Web Users (Admins):**

- Add `<CertificationManagement>` component to lot page
- Use buttons to add certificates and run checks
- View results in "View Full Traceability" page

**Result:**

- Real certification data in database
- Real compliance check results
- Populated Certificates tab
- Populated Compliance tab
- Accurate compliance status

🎉 **Users can now add real data instead of using test scripts!**
