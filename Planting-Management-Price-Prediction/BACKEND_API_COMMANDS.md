# Backend API Development Commands (Node.js)

This project has been migrated from .NET to **Node.js (Express)**.

## 1. Navigate to Backend Directory
```powershell
cd "Planting-Management-Price-Prediction/plantationmanagement"
```

## 2. Install Dependencies
```powershell
npm install
```

## 3. Environment Configuration
Create a `.env` file in the `plantationmanagement` directory with the following variables:
- `PORT` (default: 7001)
- `DATABASE_URL` (PostgreSQL connection string)
- `JWT_SECRET`
- `FIREBASE_PROJECT_ID`
- `OPENAI_API_KEY` (if using RAG features)
- `QDRANT_URL` (if using vector storage)

## 4. Run the API (Development Mode)
```powershell
npm run dev
```
This uses `nodemon` to automatically restart the server when files change.

## 5. Run the API (Production Mode)
```powershell
npm start
```

## 6. API Endpoints
- **Base URL**: `http://localhost:7001`
- **Auth**: `http://localhost:7001/api/auth`
- **Farms**: `http://localhost:7001/api/farms`
- **Agronomy**: `http://localhost:7001/api/agronomy`

## 7. Database Migration (Sequelize)
The project uses Sequelize ORM.
- **Sync Models**: Handled automatically in `src/config/db.js` (using `sync()`).

## 8. Common Scripts
- **Start**: `node src/app.js`
- **Dev**: `nodemon src/app.js`

## 9. Troubleshooting
- **Port already in use**: Kill the process on port 7001 or change `PORT` in `.env`.
- **Database Connection**: Ensure PostgreSQL is running and the connection string in `.env` is correct.
- **Firebase Keys**: Ensure `serviceAccountKey.json` is present in the root of the backend folder (but ignored by git).
