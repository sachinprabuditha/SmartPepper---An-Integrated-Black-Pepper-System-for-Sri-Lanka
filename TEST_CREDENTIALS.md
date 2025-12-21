# Test Credentials for Development

## Existing Users in Database

Your PostgreSQL database already has these users you can test with:

### Admin/Regulator Users

1. **Admin**

   - Email: `admin@gmail.com`
   - Password: _(You need to set this during registration)_
   - Role: regulator
   - ID: 451e1241-1344-409d-9219-35895cb2f0e3

2. **Sachin**
   - Email: `sachin@gmail.com`
   - Password: _(Set during registration)_
   - Role: regulator
   - ID: 99d44573-3893-473a-890e-4f389a2bf8b9

### Farmer Users

1. **Seller**

   - Email: `seller@gmail.com`
   - Password: _(Set during registration)_
   - Role: farmer
   - Phone: 7734562334
   - ID: ad5ec888-bc23-48a1-8a36-1e761bbdde9f

2. **Test Farmer 1**

   - Wallet: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
   - Role: farmer
   - ID: 5369bf74-413a-46b4-ae68-5733f050e597

3. **Test Farmer 2**
   - Wallet: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
   - Role: farmer
   - ID: 9c2f4f48-aa9c-4bb0-98cb-0661ad6c009d

### Buyer/Exporter Users

1. **Test Buyer 1**
   - Wallet: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
   - Role: buyer
   - ID: a647949c-bf1f-494d-b750-e5cd9fbe6a69

## Creating Test Users with Passwords

Since some users don't have emails/passwords yet, create new test users:

### Method 1: Via Web App

1. Open: http://localhost:3000
2. Click "Register"
3. Fill in:
   - Email: `test.farmer@example.com`
   - Password: `Password123!`
   - Name: `Test Farmer`
   - Role: `farmer`
4. Register
5. Use same credentials in mobile app!

### Method 2: Via API (cURL)

```powershell
# Register a farmer
curl http://localhost:3002/api/auth/register `
  -Method POST `
  -Body '{"email":"mobile.farmer@test.com","password":"Test123!","name":"Mobile Farmer","role":"farmer","phone":"+94771234567"}' `
  -ContentType "application/json"

# Register an exporter
curl http://localhost:3002/api/auth/register `
  -Method POST `
  -Body '{"email":"mobile.exporter@test.com","password":"Test123!","name":"Mobile Exporter","role":"exporter","phone":"+94771234568"}' `
  -ContentType "application/json"
```

### Method 3: Direct SQL (if you have psql access)

```sql
-- Connect to database
psql -U postgres -d smartpepper

-- Insert a test farmer (password is hashed bcrypt of "Password123!")
INSERT INTO users (email, password, name, role, phone, verified)
VALUES (
  'farmer.mobile@test.com',
  '$2a$10$YourHashedPasswordHere',
  'Mobile Test Farmer',
  'farmer',
  '+94771234567',
  true
);
```

## Testing Login from Mobile

### Test Credentials to Use

Create these users via web registration, then use in mobile:

**Farmer Account:**

- Email: `farmer@smartpepper.com`
- Password: `Farmer123!`
- Role: farmer

**Exporter Account:**

- Email: `exporter@smartpepper.com`
- Password: `Exporter123!`
- Role: exporter

**Admin Account:**

- Email: `admin@smartpepper.com`
- Password: `Admin123!`
- Role: admin

## Quick Test Script

Run this to create all test users at once:

```powershell
# Create multiple test users
$users = @(
    @{email="farmer@smartpepper.com"; password="Farmer123!"; name="Test Farmer"; role="farmer"},
    @{email="exporter@smartpepper.com"; password="Exporter123!"; name="Test Exporter"; role="exporter"},
    @{email="admin@smartpepper.com"; password="Admin123!"; name="Test Admin"; role="admin"}
)

foreach ($user in $users) {
    $body = $user | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3002/api/auth/register" -Method Post -Body $body -ContentType "application/json"
        Write-Host "✓ Created: $($user.email)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed: $($user.email) - $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

## Verify Users Created

```powershell
# List all users
curl http://localhost:3002/api/users -UseBasicParsing | ConvertFrom-Json | Select-Object -ExpandProperty users | Format-Table id, email, name, role
```

## Mobile App Login Test

Once users are created:

1. Open your mobile app
2. Navigate to Login screen
3. Enter:
   - Email: `farmer@smartpepper.com`
   - Password: `Farmer123!`
4. Click Login
5. Should see dashboard!

## API Login Test

Test login endpoint directly:

```powershell
# Test login
$response = curl http://localhost:3002/api/auth/login `
  -Method POST `
  -Body '{"email":"farmer@smartpepper.com","password":"Farmer123!"}' `
  -ContentType "application/json" `
  -UseBasicParsing | ConvertFrom-Json

# Show user data
$response | ConvertTo-Json -Depth 5

# Extract token
$token = $response.token
Write-Host "JWT Token: $token"
```

## Using the Token

After login, use the JWT token for authenticated requests:

```powershell
# Get current user profile
curl http://localhost:3002/api/auth/me `
  -Headers @{Authorization="Bearer $token"} `
  -UseBasicParsing | ConvertFrom-Json | ConvertTo-Json
```

## Mobile App Implementation

Your mobile app should:

1. **Save token** after successful login:

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('jwt_token', response.data['token']);
```

2. **Include token** in all requests:

```dart
final token = prefs.getString('jwt_token');
final response = await dio.get(
  '/users/me',
  options: Options(
    headers: {'Authorization': 'Bearer $token'},
  ),
);
```

3. **Check if logged in** on app start:

```dart
final token = await prefs.getString('jwt_token');
if (token != null) {
  // User is logged in
  navigateToHome();
} else {
  // Show login screen
  navigateToLogin();
}
```

## Password Requirements

When creating passwords, ensure:

- At least 8 characters
- Contains uppercase letter
- Contains lowercase letter
- Contains number
- Contains special character (optional but recommended)

Example strong passwords:

- `Farmer123!`
- `Export@2025`
- `Admin#Pass1`
- `Pepper$123`

## Security Notes

⚠️ **Important for Production:**

1. Never hardcode passwords in code
2. Always use HTTPS in production
3. Store tokens securely using `flutter_secure_storage`
4. Implement token refresh mechanism
5. Add biometric authentication option
6. Clear tokens on logout

## Troubleshooting Login Issues

### "Invalid credentials"

- Check password is correct
- Verify user exists: `SELECT * FROM users WHERE email = 'youremail@example.com';`

### "Token expired"

- Tokens expire after 7 days (default)
- Implement token refresh
- Re-login required

### "Network error"

- Verify backend is running
- Check API URL in mobile config
- Test with curl first

### "Email already registered"

- User already exists
- Try logging in instead
- Or use different email

## Ready to Go!

You now have:

- ✅ PostgreSQL database running
- ✅ Backend API accessible
- ✅ Test users created
- ✅ Mobile app configured
- ✅ Same authentication system

Login from mobile using any of the test credentials above!
