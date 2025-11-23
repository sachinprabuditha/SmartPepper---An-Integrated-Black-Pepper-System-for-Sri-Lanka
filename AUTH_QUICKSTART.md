# 🚀 Quick Start - Authentication System

## Get Started in 3 Minutes

### Step 1: Run Backend Migration

```bash
cd backend
node src/db/migrateAuth.js
```

Expected output:

```
✅ Authentication migrations completed successfully
```

### Step 2: Start All Services

**Terminal 1 - Blockchain:**

```bash
cd blockchain
npx hardhat node
```

**Terminal 2 - Backend:**

```bash
cd backend
npm run dev
```

**Terminal 3 - Frontend:**

```bash
cd web
npm run dev
```

### Step 3: Create Your First Account

1. **Open browser:** http://localhost:3001/register

2. **Choose your role:**

   - 🌾 **Farmer** - if you want to sell pepper
   - 🏢 **Exporter** - if you want to buy pepper
   - ⚙️ **Admin** - if you're managing the system

3. **Fill in details:**

   ```
   Name: John Farmer
   Email: john@example.com
   Password: farmer123
   Role: Farmer
   ```

4. **Click "Create Account"**

5. **You'll be auto-logged in and redirected to your dashboard!**

## 🧪 Test Accounts

Create these test accounts to explore all roles:

### Farmer Account

```
Name: Test Farmer
Email: farmer@test.com
Password: farmer123
Role: farmer
City: Matale
```

### Exporter Account

```
Name: Test Exporter
Email: exporter@test.com
Password: exporter123
Role: exporter
City: Colombo
```

### Admin Account

```
Name: System Admin
Email: admin@test.com
Password: admin123
Role: admin
```

## 📱 Try These Features

### As Farmer:

1. Login → Auto-redirected to farmer dashboard
2. Click "Create New Auction"
3. Fill lot details and create auction
4. View your auctions and bids

### As Exporter:

1. Login → Auto-redirected to exporter dashboard
2. Browse active auctions
3. Click "Place Bid" on any auction
4. Track your bids in dashboard

### As Admin:

1. Login → Auto-redirected to admin dashboard
2. View system statistics
3. Manage users, lots, auctions
4. Review compliance checks

## 🔗 Important URLs

- **Home:** http://localhost:3001
- **Login:** http://localhost:3001/login
- **Register:** http://localhost:3001/register
- **Farmer Dashboard:** http://localhost:3001/dashboard/farmer
- **Exporter Dashboard:** http://localhost:3001/dashboard/exporter
- **Admin Dashboard:** http://localhost:3001/dashboard/admin
- **API Docs:** http://localhost:3002/health

## ✅ Verification Checklist

After setup, verify these work:

- [ ] Can register new user
- [ ] Can login successfully
- [ ] Token stored in localStorage
- [ ] Auto-redirect to correct dashboard
- [ ] Dashboard shows user name
- [ ] Can logout and login again
- [ ] Profile loads correctly
- [ ] Different roles see different dashboards

## 🆘 Troubleshooting

**Can't register:**

- Check backend is running on port 3002
- Check database migration completed
- Check PostgreSQL is running

**Login fails:**

- Verify email and password
- Check database has the user
- Check JWT_SECRET in .env

**Not redirecting:**

- Clear browser localStorage
- Check console for errors
- Verify AuthProvider is wrapping app

**API errors:**

- Check backend logs in `backend/logs/`
- Verify API_URL in `.env.local`
- Test API directly: `curl http://localhost:3002/health`

## 🎯 Next Steps

Once authentication is working:

1. ✅ Create auction with logged-in farmer
2. ✅ Place bid with logged-in exporter
3. ✅ Review auctions as admin
4. ✅ Test profile updates
5. ✅ Check activity logs

## 📚 Full Documentation

See `AUTHENTICATION_SYSTEM.md` for:

- Complete API reference
- Security details
- Database schema
- Permission matrix
- Advanced features

---

**Ready to go!** 🚀

Start with farmer registration and create your first auction!
