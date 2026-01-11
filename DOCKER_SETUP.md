# 🐳 Docker Setup for SmartPepper

This guide explains how to set up PostgreSQL, Redis, and IPFS using Docker.

## Quick Start

```powershell
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## Default Credentials

### PostgreSQL

- **Host**: localhost
- **Port**: 5432
- **Database**: smartpepper
- **Username**: smartpepper
- **Password**: smartpepper2024

Connection String:

```
postgresql://smartpepper:smartpepper2024@localhost:5432/smartpepper
```

### Redis

- **Host**: localhost
- **Port**: 6379
- **Password**: smartpepper2024

Connection String:

```
redis://:smartpepper2024@localhost:6379
```

### IPFS

- **API**: http://localhost:5001
- **Gateway**: http://localhost:8080
- **P2P**: Port 4001

### pgAdmin (Optional - Database UI)

- **URL**: http://localhost:5050
- **Email**: admin@smartpepper.com
- **Password**: smartpepper2024

### Redis Commander (Optional - Redis UI)

- **URL**: http://localhost:8081
- No authentication required (connects automatically)

## Backend Configuration

Update `backend/.env`:

```env
# Database (Docker)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartpepper
DB_USER=smartpepper
DB_PASSWORD=smartpepper2024

# Redis (Docker)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=smartpepper2024

# IPFS (Docker)
IPFS_API_URL=http://localhost:5001
IPFS_GATEWAY_URL=http://localhost:8080
```

## Commands

### Start Services

```powershell
# Start core services (postgres + redis)
docker-compose up -d postgres redis

# Start all services including IPFS
docker-compose up -d

# Start with management tools (pgAdmin + Redis Commander)
docker-compose --profile tools up -d
```

### Stop Services

```powershell
# Stop all
docker-compose down

# Stop and remove volumes (WARNING: deletes all data!)
docker-compose down -v
```

### View Logs

```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f postgres
docker-compose logs -f redis
```

### Database Access

```powershell
# Connect to PostgreSQL
docker exec -it smartpepper-postgres psql -U smartpepper -d smartpepper

# Run SQL commands
docker exec -it smartpepper-postgres psql -U smartpepper -d smartpepper -c "SELECT * FROM users;"

# Import SQL file
docker exec -i smartpepper-postgres psql -U smartpepper -d smartpepper < backend/create-tables.sql
```

### Redis Access

```powershell
# Connect to Redis CLI
docker exec -it smartpepper-redis redis-cli -a smartpepper2024

# Test connection
docker exec -it smartpepper-redis redis-cli -a smartpepper2024 ping
```

## Troubleshooting

### Port Already in Use

```powershell
# Check what's using the port
netstat -ano | findstr :5432

# Change port in docker-compose.yml:
ports:
  - "5433:5432"  # Use 5433 instead of 5432
```

### Reset Database

```powershell
# Stop and remove containers with data
docker-compose down -v

# Start fresh
docker-compose up -d
```

### View Container Status

```powershell
docker-compose ps
docker stats
```

## Production Notes

For production, change default passwords in `docker-compose.yml`:

```yaml
environment:
  POSTGRES_PASSWORD: YOUR_SECURE_PASSWORD_HERE

command: redis-server --requirepass YOUR_SECURE_PASSWORD_HERE
```
