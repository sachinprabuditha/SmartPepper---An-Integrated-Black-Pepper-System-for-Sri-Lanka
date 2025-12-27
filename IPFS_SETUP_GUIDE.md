# IPFS Setup Guide for SmartPepper

## Problem

Your mobile app is getting this error:

```
IPFS upload error: ClientException with SocketException: Connection timed out
address = 192.168.8.116, port = 40006, uri=http://192.168.8.116:5001/api/v0/add
```

This means IPFS daemon is not running or not accessible at `192.168.8.116:5001`.

---

## Solution: Install and Configure IPFS

### Step 1: Check if IPFS is Installed

```powershell
ipfs --version
```

**If you see version number:** IPFS is installed ✅ (skip to Step 3)  
**If you get error:** IPFS not installed ❌ (continue to Step 2)

---

### Step 2: Install IPFS (If Not Installed)

#### Option A: Using Chocolatey (Recommended)

```powershell
# Install Chocolatey if you don't have it
# Run PowerShell as Administrator first
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install IPFS
choco install go-ipfs -y
```

#### Option B: Manual Installation

1. **Download IPFS:**

   - Go to: https://dist.ipfs.tech/#go-ipfs
   - Download: `go-ipfs_v0.24.0_windows-amd64.zip` (or latest version)

2. **Extract and Install:**

   ```powershell
   # Extract the downloaded zip file
   # Move ipfs.exe to a folder in your PATH, for example:
   Move-Item .\ipfs.exe C:\Windows\System32\

   # OR create a new folder and add to PATH:
   mkdir C:\ipfs
   Move-Item .\ipfs.exe C:\ipfs\
   # Then add C:\ipfs to your PATH environment variable
   ```

3. **Verify Installation:**
   ```powershell
   ipfs --version
   ```
   Should output: `ipfs version 0.24.0` (or your version)

---

### Step 3: Initialize IPFS Repository

**First time only:**

```powershell
# Initialize IPFS (creates ~/.ipfs directory)
ipfs init

# Expected output:
# generating ED25519 keypair...done
# peer identity: Qm...
# initializing IPFS node at C:\Users\YourName\.ipfs
```

---

### Step 4: Configure IPFS for Network Access

By default, IPFS only listens on `127.0.0.1` (localhost). Your mobile device needs access from network IP `192.168.8.116`.

```powershell
# Configure IPFS to listen on all network interfaces
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001

# Configure Gateway to listen on all interfaces
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080

# Enable CORS for API access (required for mobile app)
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'
```

---

### Step 5: Configure Windows Firewall

Allow IPFS through Windows Firewall:

```powershell
# Run PowerShell as Administrator
New-NetFirewallRule -DisplayName "IPFS API" -Direction Inbound -LocalPort 5001 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "IPFS Gateway" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "IPFS Swarm" -Direction Inbound -LocalPort 4001 -Protocol TCP -Action Allow
```

---

### Step 6: Start IPFS Daemon

```powershell
ipfs daemon
```

**Expected output:**

```
Initializing daemon...
go-ipfs version: 0.24.0
Repo version: 15
System version: amd64/windows
Golang version: go1.21.0
Swarm listening on /ip4/127.0.0.1/tcp/4001
Swarm listening on /ip4/192.168.8.116/tcp/4001
API server listening on /ip4/0.0.0.0/tcp/5001
WebUI: http://0.0.0.0:5001/webui
Gateway server listening on /ip4/0.0.0.0/tcp/8080
Daemon is ready
```

**Important:** Keep this terminal window open! IPFS daemon must run continuously.

---

### Step 7: Verify IPFS is Accessible

#### From Local Computer:

```powershell
# Test API endpoint
curl http://localhost:5001/api/v0/version

# Expected output:
# {"Version":"0.24.0","Commit":"..."}
```

#### From Mobile Device (or another terminal):

```powershell
# Replace 192.168.8.116 with your actual IP
curl http://192.168.8.116:5001/api/v0/version
```

**If this fails:** Check firewall settings and ensure your IP is correct.

---

### Step 8: Verify Your Computer's IP Address

Make sure `192.168.8.116` is actually your computer's IP:

```powershell
# Get your IP address
ipconfig | Select-String "IPv4"
```

**Expected output:**

```
   IPv4 Address. . . . . . . . . . . : 192.168.8.116
```

**If IP is different:** Update `mobile/lib/config/env.dart` with the correct IP.

---

## Testing IPFS Upload

### Test from Command Line:

```powershell
# Create a test file
echo "Hello IPFS" > test.txt

# Upload to IPFS
ipfs add test.txt

# Expected output:
# added QmXXXXXXX test.txt
# 11 B / 11 B [==================] 100.00%

# View in browser
start http://192.168.8.116:8080/ipfs/QmXXXXXXX
```

### Test from Mobile App:

1. Start IPFS daemon: `ipfs daemon`
2. Run mobile app: `cd mobile && flutter run`
3. Login as farmer
4. Try to create a lot with certificate images
5. Should see: "Uploading certificates to IPFS..." with progress

---

## Running IPFS Permanently

### Option 1: Run in Background Terminal

Keep the terminal with `ipfs daemon` open while developing.

### Option 2: Run as Windows Service (Production)

```powershell
# Install NSSM (Non-Sucking Service Manager)
choco install nssm -y

# Create service
nssm install IPFS "C:\Windows\System32\ipfs.exe" "daemon"

# Start service
nssm start IPFS

# Check status
nssm status IPFS
```

### Option 3: PowerShell Startup Script

Create `start-ipfs.ps1`:

```powershell
Start-Process -FilePath "ipfs" -ArgumentList "daemon" -WindowStyle Minimized
```

Add to Windows startup or Task Scheduler.

---

## Troubleshooting

### Issue 1: "ipfs: command not found"

**Solution:** IPFS not installed or not in PATH

- Install IPFS (see Step 2)
- Add IPFS directory to PATH environment variable
- Restart terminal

### Issue 2: "lock ~/.ipfs/repo.lock: someone else has the lock"

**Solution:** IPFS daemon already running

```powershell
# Find and kill existing process
Get-Process ipfs | Stop-Process -Force

# Start fresh
ipfs daemon
```

### Issue 3: "Error: serveHTTPApi: listen tcp 0.0.0.0:5001: bind: Only one usage of each socket address"

**Solution:** Port 5001 already in use

```powershell
# Find what's using port 5001
netstat -ano | findstr :5001

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F

# Or use a different port
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5002
# Then update mobile/lib/config/env.dart: ipfsApiUrl = 'http://192.168.8.116:5002'
```

### Issue 4: Connection timeout from mobile app

**Checklist:**

1. ✅ IPFS daemon running? (`ipfs daemon` in terminal)
2. ✅ Correct IP in env.dart? (`ipconfig` to verify)
3. ✅ Firewall allows port 5001? (See Step 5)
4. ✅ Mobile device on same Wi-Fi network?
5. ✅ API configured for 0.0.0.0? (`ipfs config Addresses.API`)

```powershell
# Quick diagnostic
curl http://192.168.8.116:5001/api/v0/version

# If this works, IPFS is accessible
# If this fails, check firewall and network
```

### Issue 5: "CORS policy" error

**Solution:** Configure CORS headers

```powershell
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'

# Restart daemon
ipfs daemon
```

---

## Complete Setup Script

Save this as `setup-ipfs.ps1` and run **as Administrator**:

```powershell
# Install IPFS (if using Chocolatey)
choco install go-ipfs -y

# Initialize IPFS
ipfs init

# Configure for network access
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080

# Enable CORS
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET"]'

# Configure Windows Firewall
New-NetFirewallRule -DisplayName "IPFS API" -Direction Inbound -LocalPort 5001 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "IPFS Gateway" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "IPFS Swarm" -Direction Inbound -LocalPort 4001 -Protocol TCP -Action Allow

Write-Host "`n✅ IPFS setup complete!" -ForegroundColor Green
Write-Host "Now run: ipfs daemon" -ForegroundColor Yellow
```

---

## Quick Start for Development

Every time you want to work on the app:

```powershell
# Terminal 1: Start Hardhat blockchain
cd blockchain
npx hardhat node

# Terminal 2: Deploy contracts
cd blockchain
npm run deploy:local

# Terminal 3: Start IPFS
ipfs daemon

# Terminal 4: Start backend
cd backend
npm start

# Terminal 5: Run mobile app
cd mobile
flutter run
```

---

## IPFS Web UI

Once daemon is running, access the web interface:

**URL:** http://localhost:5001/webui

Features:

- View files stored in IPFS
- Monitor connections and peers
- Check node status
- Upload files via drag-and-drop

---

## Alternative: Use Public IPFS Service (For Testing Only)

If you can't get local IPFS working, you can temporarily use a public service:

### Option A: Infura IPFS

1. Sign up at https://infura.io/
2. Create new project → IPFS
3. Get Project ID and Secret
4. Update `mobile/lib/config/env.dart`:
   ```dart
   static const String ipfsApiUrl = 'https://ipfs.infura.io:5001';
   static const String ipfsGatewayUrl = 'https://ipfs.infura.io/ipfs';
   ```

### Option B: Pinata

1. Sign up at https://pinata.cloud/
2. Get API key
3. Requires code changes to use JWT authentication

**Note:** Public services have rate limits and are not suitable for production without paid plans.

---

## For Physical Device Testing

### Ensure Mobile Device and Computer on Same Network:

1. **Computer:**

   - Connected to Wi-Fi: "YourNetwork"
   - IP: 192.168.8.116 (verify with `ipconfig`)

2. **Mobile Device:**

   - Connected to same Wi-Fi: "YourNetwork"
   - Can ping computer: `ping 192.168.8.116` (from terminal apps)

3. **Test connectivity:**
   - Open browser on mobile device
   - Navigate to: `http://192.168.8.116:5001/webui`
   - Should see IPFS Web UI

If you can't access the Web UI from your phone, the mobile app won't work either.

---

## Summary

| Step | Command                                                                  | Purpose                           |
| ---- | ------------------------------------------------------------------------ | --------------------------------- |
| 1    | `ipfs init`                                                              | Initialize IPFS (first time only) |
| 2    | `ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001`                        | Allow network access              |
| 3    | `ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'` | Enable CORS                       |
| 4    | Configure Windows Firewall                                               | Allow ports 5001, 8080, 4001      |
| 5    | `ipfs daemon`                                                            | Start IPFS (keep running)         |
| 6    | Verify: `curl http://192.168.8.116:5001/api/v0/version`                  | Test from network                 |

**Once working:** Your mobile app will successfully upload certificates to IPFS! ✅

---

**Need Help?** Check logs in the terminal running `ipfs daemon` for detailed error messages.
