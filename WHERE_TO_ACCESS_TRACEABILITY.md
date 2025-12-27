# 📍 WHERE TO ACCESS BLOCKCHAIN TRACEABILITY SCREENS

## 🎯 Quick Navigation Map

```
📱 MOBILE APP (Farmer Side)
├─ Bottom Navigation → "My Lots"
│  └─ Select any lot card
│     └─ Lot Details Screen
│        ├─ [Full Traceability] Button (GREEN) ← NEW! Opens full viewer
│        └─ [Quick Info] Button (Outlined) ← Shows blockchain TX dialog
│
└─ Bottom Navigation → "My Lots"
   └─ Tap lot card
      └─ Tap "Full Traceability" button
         └─ ✨ FULL TRACEABILITY SCREEN (5 tabs)

💻 WEB DASHBOARD (Admin Side)
├─ Sidebar → "Lot Management"
│  └─ Click any lot row
│     └─ Lot Details Page
│        └─ "Blockchain Traceability" Section
│           └─ [View Full Traceability] Button (GREEN, top-right) ← Opens full viewer
│
└─ Direct URL: /traceability/LOT-2025-001
   └─ ✨ FULL TRACEABILITY PAGE (5 tabs)
```

---

## 📱 MOBILE APP - Farmer Side

### 1️⃣ Navigation to Lot Details

**Path**: Home → My Lots → [Select Lot]

**File**: `mobile/lib/screens/farmer/farmer_lots_screen.dart`

**What you see**:

- List of farmer's lots with cards
- Each card shows: Lot ID, variety, quantity, quality, status
- **Tap any lot card** to open details

---

### 2️⃣ Lot Details Screen - **WHERE TRACEABILITY BUTTONS ARE**

**Path**: My Lots → Lot Details Screen

**File**: `mobile/lib/screens/farmer/lot_details_screen.dart` **(Lines 665-867)**

**Location of Buttons**: **Bottom of lot details, after all information**

```dart
// EXACT LOCATION IN CODE:
// After origin/farm location information
// Lines 665-867

const SizedBox(height: 16),
const Divider(),
const SizedBox(height: 12),

// ✅ TWO BUTTONS HERE:
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () async {
      if (lot.blockchainTxHash != null) {
        // Shows blockchain TX dialog (quick info)
      }
    },
    icon: const Icon(Icons.open_in_new),
    label: const Text('View on Blockchain'),  // ← BUTTON 1
  ),
)
```

**Visual Layout**:

```
┌─────────────────────────────────┐
│  ← Lot Details                  │
├─────────────────────────────────┤
│  LOT-2025-001                   │
│  Kurunegala White               │
│  500 kg • Grade A               │
│                                 │
│  Origin: Kandy, Sri Lanka       │
│  Farm: Farm A                   │
│  🌿 Organic Certified           │
│                                 │
│  ─────────────────────────      │
│                                 │
│  ┌───────────────────────────┐ │  ← BUTTON IS HERE
│  │ 🔗 View on Blockchain     │ │
│  └───────────────────────────┘ │
│                                 │
│  [Delete]                       │
└─────────────────────────────────┘
```

**What happens when you tap**:

1. **"View on Blockchain"** button → Opens dialog showing:
   - Transaction hash (copyable)
   - Network info
   - Immutability notice

---

### 🎯 TO ADD: Full Traceability Button

**I need to add this button** next to "View on Blockchain":

```dart
// UPDATED VERSION (needs to be added):
Row(
  children: [
    // Button 1: Full Traceability (PRIMARY)
    Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          context.push('/traceability/${lot.lotId}');
        },
        icon: const Icon(Icons.timeline),
        label: const Text('Full Traceability'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.forestGreen,  // Green
        ),
      ),
    ),
    const SizedBox(width: 12),
    // Button 2: Quick Info (SECONDARY)
    Expanded(
      child: OutlinedButton.icon(
        onPressed: () { /* Dialog */ },
        icon: const Icon(Icons.info_outline),
        label: const Text('Quick Info'),
      ),
    ),
  ],
)
```

**New Visual Layout** (after adding):

```
┌─────────────────────────────────┐
│  Origin: Kandy, Sri Lanka       │
│  Farm: Farm A                   │
│  🌿 Organic Certified           │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  ┌─────────────┬─────────────┐ │
│  │ 📊 Full     │ ℹ️ Quick    │ │  ← TWO BUTTONS SIDE-BY-SIDE
│  │ Traceability│   Info      │ │
│  └─────────────┴─────────────┘ │
│                                 │
│  [Delete]                       │
└─────────────────────────────────┘
```

---

### 3️⃣ Full Traceability Screen - **THE DESTINATION**

**Path**: My Lots → Lot Details → [Full Traceability] Button

**File**: `mobile/lib/screens/shared/traceability_screen.dart`

**Route**: `/traceability/:lotId`

**What you see**:

```
┌─────────────────────────────────┐
│  ← Blockchain Traceability      │
├─────────────────────────────────┤
│ Timeline│Processing│Certificates│
│   Compliance  │  Blockchain     │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │  Traceability Statistics    │ │
│ │  [24 Events][12 TX][3 Days] │ │
│ └─────────────────────────────┘ │
│                                 │
│  TIMELINE TAB (Default):        │
│  ●─ Lot registered             │
│  │   2 days ago                │
│  │   🔗 0xabc...123 ✅        │
│  │                             │
│  ●─ Harvest completed          │
│  │   1 day ago                 │
│  │   🔗 0xdef...456 ✅        │
│                                 │
└─────────────────────────────────┘
```

**5 Interactive Tabs**:

1. **Timeline**: Complete chronological history with icons
2. **Processing**: All stages (harvest, drying, grading, packaging)
3. **Certificates**: Organic, quality, export certificates
4. **Compliance**: EU, FDA, Middle East checks
5. **Blockchain**: NFT passport, transaction hashes, network info

---

## 💻 WEB DASHBOARD - Admin Side

### 1️⃣ Lot Management Page

**Path**: Dashboard → Sidebar → "Lot Management"

**File**: `web/src/app/dashboard/admin/lots/page.tsx`

**What you see**:

- Table of all lots with columns: Lot ID, Farmer, Variety, Quantity, Status
- Search and filter options
- **Click any lot row** to view details

---

### 2️⃣ Lot Details Page - **WHERE TRACEABILITY BUTTON IS**

**Path**: Lot Management → [Click Lot Row]

**File**: `web/src/app/dashboard/admin/lots/[lotId]/page.tsx` **(Lines 329-442)**

**URL**: `/dashboard/admin/lots/LOT-2025-001`

**Location of Button**: **Top-right of "Blockchain Traceability" section**

```tsx
// EXACT LOCATION IN CODE:
// Lines 329-442

{
  /* Blockchain Traceability */
}
{
  lot.blockchain_tx_hash && (
    <section className="mb-8">
      <h2 className="text-xl font-semibold ... flex items-center gap-2">
        ⚡ Blockchain Traceability
      </h2>

      {/* Beautiful purple-blue gradient card with: */}
      <div className="bg-gradient-to-br from-purple-50 to-blue-50 ...">
        <div className="grid grid-cols-2 gap-4">
          {/* Transaction Hash */}
          {/* Network */}
          {/* Farmer Wallet */}
          {/* Smart Contract */}
        </div>
      </div>
    </section>
  );
}
```

**Visual Layout** (CURRENT):

```
┌────────────────────────────────────────────┐
│  Lot Details - LOT-2025-001                │
├────────────────────────────────────────────┤
│                                            │
│  [Basic Info] [Images] [Actions]          │
│                                            │
│  ⚡ Blockchain Traceability               │
│  ┌──────────────────────────────────────┐ │
│  │ ✅ Verified on Blockchain            │ │
│  │                                      │ │
│  │ ┌───────────┬───────────┐           │ │
│  │ │TX Hash    │ Network   │           │ │
│  │ │0xabc...   │ Hardhat   │           │ │
│  │ ├───────────┼───────────┤           │ │
│  │ │Farmer     │ Contract  │           │ │
│  │ │0x709...   │ 0x5FC...  │           │ │
│  │ └───────────┴───────────┘           │ │
│  │                                      │ │
│  │ ℹ️ Immutable Record notice          │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  📸 Lot Pictures                          │
└────────────────────────────────────────────┘
```

**🎯 TO ADD: View Full Traceability Button**

**Updated Layout** (with button):

```
┌────────────────────────────────────────────┐
│  ⚡ Blockchain Traceability  [View Full ↗] │  ← BUTTON HERE
│  ┌──────────────────────────────────────┐ │
│  │ ✅ Verified on Blockchain            │ │
│  │ ...                                  │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

**Code to add**:

```tsx
<div className="flex items-center justify-between mb-4">
  <h2>⚡ Blockchain Traceability</h2>
  <button
    onClick={() => router.push(`/traceability/${params.lotId}`)}
    className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg"
  >
    📊 View Full Traceability
  </button>
</div>
```

---

### 3️⃣ Full Traceability Page - **THE DESTINATION**

**Path**: Lot Details → [View Full Traceability] Button

**File**: `web/src/app/traceability/[lotId]/page.tsx`

**URL**: `http://localhost:3000/traceability/LOT-2025-001`

**Direct Access**: You can also navigate directly to this URL!

**What you see**:

```
┌────────────────────────────────────────────────────────┐
│ ← Back    🔍 Blockchain Traceability        [Export ↓]│
│ Lot ID: LOT-2025-001                                  │
│ Complete audit trail with 12 blockchain transactions   │
│                                                        │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                 │
│ │  24  │ │  12  │ │   4  │ │   3  │                 │
│ │Events│ │  TX  │ │Stages│ │ Days │                 │
│ └──────┘ └──────┘ └──────┘ └──────┘                 │
├────────────────────────────────────────────────────────┤
│ Timeline │ Processing │ Certificates │ Compliance │ B │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ✅ Lot registered on blockchain         ✓ Verified   │
│     By: Farmer John                                   │
│     Jan 15, 2025 at 8:00 AM                          │
│     🔗 0xabc123...def456              [Copy]         │
│                                                        │
│  ⚙️ Harvest completed                   ✓ Verified   │
│     By: John Doe                                      │
│     Jan 15, 2025 at 10:00 AM                         │
│     🔗 0xdef456...abc123              [Copy]         │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**Features**:

- **5 tabs**: Timeline, Processing, Certificates, Compliance, Blockchain
- **Export button**: Download complete JSON
- **Back button**: Return to previous page
- **Copy buttons**: Copy any blockchain hash
- **Responsive**: Works on mobile, tablet, desktop

---

## 🔌 API ENDPOINT - Direct Access

**Endpoint**: `GET /api/traceability/:lotId`

**File**: `backend/src/routes/traceability.js`

**URL**: `http://192.168.8.116:3002/api/traceability/{lotId}`

**Registered in**: `backend/src/server.js` (Line 68)

```javascript
// backend/src/server.js
app.use("/api/traceability", require("./routes/traceability"));
```

**Test it now**:

```bash
# Get complete traceability for a lot
curl http://192.168.8.116:3002/api/traceability/LOT-2025-001 | jq

# Or in PowerShell:
Invoke-RestMethod -Uri "http://192.168.8.116:3002/api/traceability/LOT-2025-001"
```

---

## 📋 Summary of Access Points

| Platform          | Starting Point               | Button/Link                                          | Destination                       |
| ----------------- | ---------------------------- | ---------------------------------------------------- | --------------------------------- |
| **📱 Mobile**     | My Lots → Lot Details        | ` [Full Traceability]` (Green button)                | Full Traceability Screen (5 tabs) |
| **💻 Web Admin**  | Lot Management → Lot Details | `[View Full Traceability]` (Green button, top-right) | Full Traceability Page (5 tabs)   |
| **🔌 API**        | -                            | `GET /api/traceability/:lotId`                       | Complete JSON response            |
| **🔗 Direct URL** | Browser                      | `/traceability/LOT-2025-001`                         | Full Traceability Page            |

---

## 🎯 EXACT FILE LOCATIONS

### Mobile App Files:

1. **Lot List Screen**: `mobile/lib/screens/farmer/farmer_lots_screen.dart`
2. **Lot Details Screen**: `mobile/lib/screens/farmer/lot_details_screen.dart`
   - **Lines 665-867**: Blockchain buttons section
3. **Full Traceability Screen**: `mobile/lib/screens/shared/traceability_screen.dart`
   - **NEW**: Complete implementation with 5 tabs (900+ lines)

### Web Dashboard Files:

1. **Lot Management Page**: `web/src/app/dashboard/admin/lots/page.tsx`
2. **Lot Details Page**: `web/src/app/dashboard/admin/lots/[lotId]/page.tsx`
   - **Lines 329-442**: Blockchain traceability section
3. **Full Traceability Page**: `web/src/app/traceability/[lotId]/page.tsx`
   - **NEW**: Complete implementation with 5 tabs (700+ lines)

### Backend Files:

1. **Traceability API**: `backend/src/routes/traceability.js` (**NEW**, 500+ lines)
2. **Server Routes**: `backend/src/server.js` (Line 68)

---

## 🚀 How to Navigate RIGHT NOW

### For Mobile (Farmer):

1. **Open mobile app**: `cd mobile && flutter run`
2. **Login as farmer** (wallet: `0x709...`)
3. **Tap "My Lots"** in bottom navigation
4. **Select any lot card**
5. **Scroll to bottom** of lot details
6. **Tap "View on Blockchain"** button (current)
   - Or after update: **Tap "Full Traceability"** button

### For Web (Admin):

1. **Open web dashboard**: `http://localhost:3000`
2. **Login as admin**
3. **Click "Lot Management"** in sidebar
4. **Click any lot row** to view details
5. **Scroll down to "Blockchain Traceability"** section
6. **Click "View Full Traceability"** button (after adding)
   - Or navigate directly: `/traceability/LOT-2025-001`

### Direct API Test:

```bash
curl http://192.168.8.116:3002/api/traceability/LOT-2025-001
```

---

## 📝 NEXT STEPS TO COMPLETE INTEGRATION

### ✅ Already Done:

- [x] Created full traceability API endpoint
- [x] Created mobile traceability screen (5 tabs)
- [x] Created web traceability page (5 tabs)
- [x] Registered API route in server

### ⚠️ Need to Add:

- [ ] **Mobile**: Replace single button with two buttons (Full Traceability + Quick Info)
- [ ] **Web**: Add "View Full Traceability" button next to section heading

**Would you like me to add these buttons now?** I can update both files to add the navigation buttons to the full traceability viewers.
