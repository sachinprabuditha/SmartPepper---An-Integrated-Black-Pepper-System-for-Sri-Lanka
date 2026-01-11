# Physical Device Setup Guide

## ✅ Configuration Complete for Huawei Device

Your mobile app is now configured to connect to your development server from a physical device.

---

## 🔧 What Was Changed

### 1. **Network Configuration** (`lib/config/env.dart`)

**Updated from:**

```dart
static const String apiBaseUrl = 'http://10.0.2.2:3002/api'; // Emulator only
```

**Updated to:**

```dart
static const String apiBaseUrl = 'http://192.168.8.116:3002/api'; // Physical device
```

### 2. **Timeout Settings** (`lib/services/api_service.dart`)

Increased connection timeout from 30 to 60 seconds for physical device connections:

```dart
connectTimeout: const Duration(seconds: 60),
receiveTimeout: const Duration(seconds: 60),
```

---

## 📱 Your Network Details

**Computer IP Address:** `192.168.8.116` (Wi-Fi)  
**Backend Port:** `3002`  
**WebSocket Port:** `3002`

**Connection Status:**

- ✅ Backend accessible at `http://192.168.8.116:3002`
- ✅ Firewall configured (Node.js allowed)
- ✅ Server listening on all interfaces

---

## 🚀 How to Use

### **Step 1: Ensure Both Devices on Same Network**

- Computer connected to Wi-Fi: `192.168.8.116`
- Huawei phone connected to **same Wi-Fi network**

### **Step 2: Start Backend Server**

```bash
cd backend
npm start
```

Verify it's running:

```bash
curl http://192.168.8.116:3002/health
```

### **Step 3: Run Mobile App**

```bash
cd mobile
flutter run
```

The app will now connect to your computer's backend!

---

## 🧪 Testing Connection

### **From Your Computer:**

```powershell
# Test health endpoint
curl http://192.168.8.116:3002/health

# Test login endpoint
curl http://192.168.8.116:3002/api/auth/login -Method POST `
  -Body '{"email":"farmer@smartpepper.com","password":"Farmer123!"}' `
  -ContentType "application/json"
```

### **From Your Phone:**

Open browser on phone and navigate to:

```
http://192.168.8.116:3002/health
```

You should see:

```json
{"status":"healthy","timestamp":"...","uptime":...}
```

---

## 🔄 Switching Between Devices

### **For Android Emulator:**

```dart
static const String apiBaseUrl = 'http://10.0.2.2:3002/api';
```

### **For Physical Device:**

```dart
static const String apiBaseUrl = 'http://192.168.8.116:3002/api';
```

### **For iOS Simulator:**

```dart
static const String apiBaseUrl = 'http://localhost:3002/api';
```

---

## 🐛 Troubleshooting

### Problem: Still getting timeout errors

**Check 1: Same Wi-Fi Network**

```powershell
# On computer
ipconfig

# On phone
Settings → Wi-Fi → Connected network details
# Ensure both start with 192.168.8.x
```

**Check 2: Backend Running**

```powershell
# Check if backend is running
Get-Process node -ErrorAction SilentlyContinue

# Test from computer
curl http://192.168.8.116:3002/health
```

**Check 3: Firewall**

```powershell
# Check firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Node*"}
```

If blocked, allow Node.js through firewall:

```powershell
New-NetFirewallRule -DisplayName "Node.js Server" `
  -Direction Inbound -LocalPort 3002 -Protocol TCP -Action Allow
```

**Check 4: Phone Can Reach Computer**
On phone, open browser and try:

```
http://192.168.8.116:3002/health
```

### Problem: IP address changed

Your IP address changes when you switch networks. To find current IP:

```powershell
Get-NetIPAddress -AddressFamily IPv4 | `
  Where-Object {$_.InterfaceAlias -eq "Wi-Fi"} | `
  Select-Object IPAddress
```

Update `lib/config/env.dart` with the new IP.

---

## 📊 Network Architecture

```
┌─────────────────┐
│  Huawei Phone   │
│  192.168.8.xxx  │
└────────┬────────┘
         │ Wi-Fi
         │ Same Network
         │
┌────────▼────────┐
│   Wi-Fi Router  │
│  192.168.8.1    │
└────────┬────────┘
         │
         │
┌────────▼────────┐
│   Your Computer │
│  192.168.8.116  │
│                 │
│  Backend:3002   │
│  Blockchain:8545│
└─────────────────┘
```

---

## 🔐 Security Note

This configuration is for **development only**. Your computer's IP is accessible to all devices on the same network.

**Production deployment should use:**

- HTTPS with SSL certificates
- Cloud-hosted backend (AWS, Azure, etc.)
- Proper domain name
- API authentication & rate limiting
- VPN or private network

---

## ✨ Next Steps

1. **Hot Reload:** Changes to Dart code will hot reload automatically
2. **Backend Changes:** Restart backend server after code changes
3. **Network Changes:** Update IP in `env.dart` if you change networks
4. **Build APK:** For testing without USB:
   ```bash
   flutter build apk --release
   ```
   Install the APK on your Huawei device

---

## 📱 Test Login Credentials

**Farmer Account:**

- Email: `farmer@smartpepper.com`
- Password: `Farmer123!`

**Exporter Account:**

- Email: `exporter@smartpepper.com`
- Password: `Exporter123!`

---

## ✅ Verification Checklist

Before testing on phone:

- [ ] Backend server running (`npm start`)
- [ ] Computer IP is `192.168.8.116` (or updated in env.dart)
- [ ] Phone connected to same Wi-Fi network
- [ ] Health endpoint accessible from phone browser
- [ ] Firewall allows Node.js (port 3002)
- [ ] App recompiled with new configuration

---

## 🎯 Success Indicators

**Login should now work if you see:**

- ✅ No timeout errors
- ✅ Login button shows loading indicator
- ✅ Error message for wrong credentials: "Invalid email or password"
- ✅ Success navigates to home screen
- ✅ Backend logs show incoming requests

**Check backend logs for:**

```
POST /api/auth/login 200 - 45ms
```

---

## 💡 Pro Tips

1. **Static IP:** Consider setting a static IP for your computer during development
2. **Multiple Devices:** All phones on same Wi-Fi can connect using same IP
3. **Debug Mode:** Keep backend terminal visible to see API requests
4. **Network Changes:** Airport/coffee shop Wi-Fi will need new IP configuration
5. **Hot Restart:** Use `flutter run` with `R` key for full restart after env changes

---

Your app should now work perfectly on your Huawei device! 🎉
