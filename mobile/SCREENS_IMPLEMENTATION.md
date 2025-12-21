# SmartPepper Mobile - Screens Implementation Summary

## Overview

Created login, sign up (register), and home screens for the SmartPepper mobile application with the official brand color scheme.

## Brand Colors Applied

| Color Name          | Hex Code | Usage                                       |
| ------------------- | -------- | ------------------------------------------- |
| **Forest Green**    | #013220  | Main Background, Sidebars                   |
| **Pepper Gold**     | #D3AF5E  | Logo, Primary Buttons, Active States, Icons |
| **Deep Emerald**    | #044422  | Cards, Section Backgrounds                  |
| **Sri Lankan Leaf** | #228B22  | Success States, "Price Up" indicators       |

## Files Created

### 1. Login Screen

**File:** `lib/screens/login_screen.dart`

**Features:**

- Email and password input fields with validation
- Password visibility toggle
- "Forgot Password" link (placeholder)
- Sign up navigation link
- Loading state during authentication
- Full SmartPepper branding with logo and colors
- Error handling with snackbar notifications

**Design Elements:**

- Forest Green background
- Pepper Gold accents and buttons
- Deep Emerald input fields
- Circular logo with eco icon (temporary)
- Responsive layout with SafeArea

### 2. Register Screen (Sign Up)

**File:** `lib/screens/register_screen.dart`

**Features:**

- Role selection toggle (Farmer/Exporter)
- Full name, email, phone, password fields
- Confirm password validation
- Password visibility toggles
- Back navigation to login
- Loading state during registration
- Form validation for all fields

**Design Elements:**

- Interactive role selector with visual feedback
- Pepper Gold highlights for selected role
- Deep Emerald input fields
- Consistent branding throughout
- Smooth navigation experience

### 3. Exporter Home Screen

**File:** `lib/screens/exporter_home_screen.dart`

**Features:**

- Welcome header with branding
- Three quick action cards:
  - Live Auctions (with gavel icon)
  - My Wallet (with wallet icon)
  - Recent Bids (with history icon)
- "Swipe to Bid" call-to-action button
- Dashboard overview section with stats:
  - Active Bids: 12
  - Won Auctions: 8
  - Total Spent: 45K
- Bottom navigation bar (5 tabs):
  - Home
  - Scan
  - Report (with notification badge)
  - Reports
  - Account

**Design Elements:**

- Matches the provided screenshot design
- Circular action buttons with icons
- Sri Lankan Leaf green for action states
- Pepper Gold for active navigation
- Deep Emerald for card backgrounds

### 4. Farmer Home Screen

**File:** `lib/screens/farmer_home_screen.dart`

**Features:**

- Personalized welcome message
- Quick action cards:
  - Create Lot (Pepper Gold)
  - My Lots (Sri Lankan Leaf)
- Overview section with 4 statistics:
  - Active Lots: 8
  - In Auction: 3
  - Sold: 24
  - Revenue: $12.5K
- Recent activity feed:
  - Lot sales
  - New bids
  - Certificate approvals
- Floating action button for quick lot creation
- Bottom navigation (same 5 tabs as exporter)

**Design Elements:**

- Dashboard-style layout
- Color-coded statistics
- Activity timeline with icons
- Consistent navigation experience
- FAB for primary action

## Theme Updates

### Updated Files:

**File:** `lib/config/theme.dart`

**Changes:**

- Added SmartPepper brand colors as constants:
  - `forestGreen = #013220`
  - `pepperGold = #D3AF5E`
  - `deepEmerald = #044422`
  - `sriLankanLeaf = #228B22`
- Updated scaffold background to Forest Green
- Changed primary color to Pepper Gold
- Updated card color to Deep Emerald
- Modified input decoration for dark theme
- Updated button themes with brand colors
- Set app bar to use Forest Green with Pepper Gold accents

## Routes Configuration

### Updated Files:

**File:** `lib/config/routes.dart`

**Changes:**

- Added import for new screens
- Created inline placeholder widgets for 未 implemented screens
- Updated farmer dashboard route to use `FarmerHomeScreen`
- Updated exporter dashboard route to use `ExporterHomeScreen`
- Added additional routes for farmer lots

**Active Routes:**

- `/` - Splash Screen
- `/login` - Login Screen ✅
- `/register` - Register Screen ✅
- `/farmer/dashboard` - Farmer Home ✅
- `/exporter/dashboard` - Exporter Home ✅
- `/farmer/create-lot` - Create Lot (placeholder)
- `/farmer/lots` - My Lots (placeholder)
- `/exporter/auctions` - Browse Auctions (placeholder)
- `/exporter/wallet` - Wallet (placeholder)
- `/exporter/bids` - Recent Bids (placeholder)

## Provider Updates

### Updated Files:

**File:** `lib/providers/auth_provider.dart`

**Changes:**

- Added `phone` parameter to register method (optional)
- Updated registration API call to include phone if provided

## Assets Created

### Logo Assets:

1. **`assets/images/logo.svg`**

   - Temporary SVG logo with pepper leaf design
   - Uses brand colors (Forest Green, Pepper Gold, Sri Lankan Leaf)
   - Circular design with "SmartPepper" text
   - Replace with actual logo when available

2. **`assets/images/placeholder.txt`**
   - Placeholder file for future images

## Navigation Flow

```
Splash Screen (2s)
    ↓
[If Not Authenticated]
    ↓
Login Screen ←→ Register Screen
    ↓
[After Login/Register]
    ↓
    ├── Farmer → Farmer Home Screen
    │       ↓
    │   - Create Lot
    │   - My Lots
    │   - Activity
    │   - Reports
    │   - Profile
    │
    └── Exporter → Exporter Home Screen
            ↓
        - Live Auctions
        - My Wallet
        - Recent Bids
        - Browse Lots
        - Profile
```

## Screen Features Summary

| Feature           | Login | Register | Farmer Home | Exporter Home |
| ----------------- | ----- | -------- | ----------- | ------------- |
| Form Validation   | ✅    | ✅       | -           | -             |
| Loading States    | ✅    | ✅       | ✅          | ✅            |
| Error Handling    | ✅    | ✅       | ✅          | ✅            |
| Navigation        | ✅    | ✅       | ✅          | ✅            |
| Brand Colors      | ✅    | ✅       | ✅          | ✅            |
| Responsive Design | ✅    | ✅       | ✅          | ✅            |
| Bottom Nav        | -     | -        | ✅          | ✅            |
| Quick Actions     | -     | -        | ✅          | ✅            |
| Stats Dashboard   | -     | -        | ✅          | ✅            |
| Activity Feed     | -     | -        | ✅          | -             |

## Next Steps

### Immediate:

1. **Run the app** to test all screens:

   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

2. **Replace placeholder logo**:
   - Add actual SmartPepper logo to `assets/images/`
   - Update screens to use actual logo file

### Short-term:

1. **Implement placeholder screens**:

   - Create Lot Screen
   - My Lots Screen
   - Browse Lots Screen
   - Live Auction Screen
   - Wallet Screen
   - QR Scanner Screen

2. **Backend Integration**:
   - Start backend server
   - Test API connectivity
   - Verify authentication flow
   - Test user registration and login

### Medium-term:

1. **Add real data**:

   - Connect to actual API endpoints
   - Display real user information
   - Show actual statistics
   - Load real activity data

2. **Implement features**:
   - Lot creation with image upload
   - Real-time bidding
   - Blockchain integration
   - QR code scanning
   - Push notifications

## Testing Checklist

- [ ] Login screen displays correctly
- [ ] Register screen displays correctly
- [ ] Farmer home screen displays correctly
- [ ] Exporter home screen displays correctly
- [ ] Role selection works in register screen
- [ ] Password visibility toggle works
- [ ] Form validation works properly
- [ ] Navigation between screens works
- [ ] Bottom navigation works
- [ ] Quick action buttons navigate correctly
- [ ] Back button works properly
- [ ] Theme colors applied consistently
- [ ] Responsive on different screen sizes

## Known Issues / TODO

1. **Logo**: Using temporary eco icon, need actual logo
2. **Images**: All images are placeholders
3. **API**: Need backend server running for actual authentication
4. **Blockchain**: Web3 integration not tested yet
5. **Fonts**: Poppins fonts commented out, using system fonts
6. **Icons**: Using Material icons, may need custom icons later

## Color Reference Guide

Use these constants in your code:

```dart
import '../config/theme.dart';

// Background
AppTheme.forestGreen

// Primary buttons, active states
AppTheme.pepperGold

// Cards, sections
AppTheme.deepEmerald

// Success, positive actions
AppTheme.sriLankanLeaf

// Errors
AppTheme.errorColor
```

## Dependencies Used

All UI components use standard Flutter Material Design widgets:

- `TextField` with custom styling
- `ElevatedButton` with brand colors
- `Card` for container elements
- `BottomNavigationBar` for navigation
- `FloatingActionButton` for primary actions
- `ScaffoldMessenger` for notifications

No additional UI dependencies were added - all within existing pubspec.yaml packages.

---

**Status:** ✅ Complete and ready for testing
**Created:** December 20, 2025
**Version:** 1.0.0
