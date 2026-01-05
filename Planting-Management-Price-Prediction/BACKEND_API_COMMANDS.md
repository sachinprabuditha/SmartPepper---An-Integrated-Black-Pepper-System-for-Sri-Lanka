# Backend API Development Commands

## 1. Navigate to Backend Directory
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"
```

## 2. Restore NuGet Packages
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"
dotnet restore
```

## 3. Build the Project
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"
dotnet build
```

## 4. Run the API (Development Mode)
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"
dotnet run
```

The API will start on:
- **HTTP**: `http://localhost:7001`
- **HTTPS**: `https://localhost:7000`
- **Swagger UI**: `http://localhost:7001` (root URL)

### Accessing Swagger UI

**Automatic Browser Opening:**
- When running from Visual Studio, the browser should open automatically to `http://localhost:7001`
- When running from command line (`dotnet run`), the browser may or may not open automatically depending on your system settings

**Manual Access:**
If the browser doesn't open automatically, manually navigate to:
- **Swagger UI**: `http://localhost:7001`
- **Swagger JSON**: `http://localhost:7001/swagger/v1/swagger.json`

**Quick Access Command (PowerShell):**
```powershell
# After starting the API, open Swagger UI in your default browser
Start-Process "http://localhost:7001"
```

**Note**: Swagger UI is configured to be at the root URL, so just go to `http://localhost:7001` in your browser.

## 5. Run with Specific Environment
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"
dotnet run --environment Development
```

## 6. Run in Release Mode
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"
dotnet run --configuration Release
```

## 7. Stop the API
Press `Ctrl+C` in the terminal where the API is running

## 8. Clean Build (if you have issues)
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"
dotnet clean
dotnet restore
dotnet build
dotnet run
```

## 9. Watch Mode (Auto-reload on file changes)
```powershell
cd "F:\Year 4\My Research\YResearchProject\SKR-Backend-API"
dotnet watch run
```

This will automatically restart the API when you make code changes.

## 10. Build Without Running
```powershell
cd "F:\Year 4\My Research\YResearchProject\SKR-Backend-API"
dotnet build --no-restore
```

## 11. Check if API is Running
Open your browser and navigate to:
- **Swagger UI**: `http://localhost:7001` (root URL - Swagger is configured here)
- **Swagger JSON**: `http://localhost:7001/swagger/v1/swagger.json`

Or use PowerShell to test:
```powershell
# Test if API is running
Invoke-WebRequest -Uri "http://localhost:7001/swagger/v1/swagger.json" -UseBasicParsing

# Or test the root (Swagger UI)
Invoke-WebRequest -Uri "http://localhost:7001" -UseBasicParsing
```

**Troubleshooting Swagger UI:**
- If Swagger UI doesn't load, make sure the API is running (`dotnet run`)
- Check the console output for any errors
- Try accessing `http://localhost:7001/swagger/v1/swagger.json` directly to see if Swagger is generating the JSON
- Make sure you're using HTTP (port 7001), not HTTPS (port 7000) unless you have SSL certificates configured

## 12. View API Logs
When running with `dotnet run`, logs will appear in the terminal. For more detailed logging, check:
- Console output (terminal)
- `appsettings.json` and `appsettings.Development.json` for log level configuration

## 13. Run Database Migrations (if using EF Core Migrations)
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"
dotnet ef database update
```

## 14. Create New Migration (if using EF Core Migrations)
```powershell
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"
dotnet ef migrations add MigrationName
```

## Quick Reference

### Common Workflow
```powershell
# 1. Navigate to backend directory
cd "F:\Year 4\My Research\ResearchProject\SKR-Backend-API"

# 2. Restore packages (first time or after adding new packages)
dotnet restore

# 3. Build the project
dotnet build

# 4. Run the API
dotnet run

# Or use watch mode for auto-reload
dotnet watch run
```

### API Endpoints
- **Base URL**: `http://localhost:7001`
- **Swagger UI**: `http://localhost:7001`
- **API Endpoints**: `http://localhost:7001/api/{controller}/{action}`

### Important Notes
- The API uses **PostgreSQL** database (configured in `appsettings.json`)
- Make sure PostgreSQL is running before starting the API
- **CORS** is enabled to allow requests from the Flutter app
- **JWT Authentication** is configured for secure API access
- In Development mode, **Swagger UI** is available at the root URL

### Troubleshooting

#### Port Already in Use
If port 7001 is already in use, you can:
1. Stop the process using the port
2. Or change the port in `Properties/launchSettings.json`

#### Database Connection Issues
Check your `appsettings.json` connection string:
```json
"ConnectionStrings": {
  "DefaultConnection": "Host=localhost;Port=5432;Database=ResearchDB;Username=postgres;Password=123456"
}
```

#### Build Errors
1. Clean and rebuild:
   ```powershell
   dotnet clean
   dotnet restore
   dotnet build
   ```

2. Check for missing NuGet packages:
   ```powershell
   dotnet restore
   ```

