# 🔑 SmartPepper Default Credentials Reference

## Docker Services (docker-compose.yml)

### PostgreSQL Database

```
Host:     localhost
Port:     5432
Database: smartpepper
Username: smartpepper
Password: smartpepper2024

Connection String:
postgresql://smartpepper:smartpepper2024@localhost:5432/smartpepper

psql Command:
psql -h localhost -U smartpepper -d smartpepper
```

### Redis Cache

```
Host:     localhost
Port:     6379
Password: smartpepper2024

Connection String:
redis://:smartpepper2024@localhost:6379

redis-cli Command:
redis-cli -h localhost -p 6379 -a smartpepper2024
```

### IPFS Node

```
API:      http://localhost:5001
Gateway:  http://localhost:8080
P2P Port: 4001
No authentication required
```

### pgAdmin (Web Database Management)

```
URL:      http://localhost:5050
Email:    admin@smartpepper.com
Password: smartpepper2024

After login, add PostgreSQL server:
  Name:     SmartPepper DB
  Host:     postgres (or host.docker.internal on Windows/Mac)
  Port:     5432
  Database: smartpepper
  Username: smartpepper
  Password: smartpepper2024
```

### Redis Commander (Web Redis Management)

```
URL: http://localhost:8081
No authentication required (auto-connects)
```

---

## Hardhat Local Blockchain

### Default Test Accounts (10000 ETH each)

**Account #0 (Deployer):**

```
Address:     0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**Account #1 (Farmer):**

```
Address:     0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

**Account #2 (Exporter):**

```
Address:     0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
```

### Network Configuration

```
RPC URL:  http://127.0.0.1:8545
Chain ID: 1337
Network:  Hardhat Local
```

---

## Application URLs

```
Backend API:       http://localhost:3002
Web Dashboard:     http://localhost:3000
Mobile App:        Via emulator/device
Blockchain Node:   http://127.0.0.1:8545

Database UI:       http://localhost:5050
Redis UI:          http://localhost:8081
IPFS Gateway:      http://localhost:8080
```

---

## Smart Contract Addresses (After Deployment)

```
PepperAuction:     0x70e0bA845a1A0F2DA3359C97E0285013525FFC49
PepperPassport:    0x998abeb3E57409262aE5b751f60747921B33613E
```

---

## Quick Commands

### Start All Services

```powershell
# Docker services
docker-compose up -d

# Blockchain
cd blockchain && npm run node

# Backend
cd backend && npm run dev

# Web
cd web && npm run dev

# Mobile
cd mobile && flutter run
```

### Check Status

```powershell
# Docker
docker-compose ps

# PostgreSQL
docker exec -it smartpepper-postgres pg_isready

# Redis
docker exec -it smartpepper-redis redis-cli -a smartpepper2024 ping

# Backend health
curl http://localhost:3002/api/health
```

### Stop Services

```powershell
# Docker
docker-compose down

# Keep data volumes
docker-compose down

# Remove data (CAUTION!)
docker-compose down -v
```

---

## Security Notes

⚠️ **IMPORTANT**: These are development credentials!

For production:

1. Change all passwords in `docker-compose.yml`
2. Use environment variables instead of hardcoded values
3. Never commit real credentials to Git
4. Use strong, unique passwords for each service
5. Enable SSL/TLS for all connections
6. Restrict network access with firewall rules

---

## Environment File (.env) Summary

**backend/.env** (with Docker):

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartpepper
DB_USER=smartpepper
DB_PASSWORD=smartpepper2024

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=smartpepper2024

IPFS_API_URL=http://127.0.0.1:5001
IPFS_GATEWAY_URL=http://127.0.0.1:8080
```

---

**Need Help?** See [DOCKER_SETUP.md](DOCKER_SETUP.md) for detailed documentation.
