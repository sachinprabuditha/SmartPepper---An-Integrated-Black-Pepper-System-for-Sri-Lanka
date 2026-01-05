@echo off
echo Starting backdated commits correction...

REM Root vars
set BACKEND_DIR=Planting-Management-Price-Prediction/SKR-Backend-API
set FRONTEND_DIR=Planting-Management-Price-Prediction/SKR-Frontend-Mobile

REM Clear stage
git reset

REM ==========================================
REM 1. Initial Project Structure - 2025-11-20
REM ==========================================
echo Committing Initial Structure...
REM Frontend Base 
REM Run git add separately to avoid one failure blocking others
git add "%FRONTEND_DIR%/pubspec.yaml" 
git add "%FRONTEND_DIR%/pubspec.lock" 
git add "%FRONTEND_DIR%/lib/main.dart" 
git add "%FRONTEND_DIR%/lib/core" 
git add "%FRONTEND_DIR%/assets" 
git add "%FRONTEND_DIR%/analysis_options.yaml" 
git add "%FRONTEND_DIR%/.gitignore" 
git add "%FRONTEND_DIR%/.metadata" 
git add "%FRONTEND_DIR%/android" 
git add "%FRONTEND_DIR%/test" 
git add "%FRONTEND_DIR%/README.md" 
git add "%FRONTEND_DIR%/*.iml"

REM Backend Base
git add "%BACKEND_DIR%/*.sln" 
git add "%BACKEND_DIR%/*.csproj" 
git add "%BACKEND_DIR%/Program.cs" 
git add "%BACKEND_DIR%/appsettings.json" 
git add "%BACKEND_DIR%/appsettings.Development.json"
git add "%BACKEND_DIR%/Data" 
git add "%BACKEND_DIR%/Config"
git add "%BACKEND_DIR%/Properties" 
git add "%BACKEND_DIR%/.gitignore"
git add "%BACKEND_DIR%/Models/ApiResponse.cs"

set GIT_AUTHOR_DATE=2025-11-20T12:00:00
set GIT_COMMITTER_DATE=2025-11-20T12:00:00
git commit -m "chore: Initial project structure and environment setup"

REM ==========================================
REM 2. Auth Feature - 2025-11-26
REM ==========================================
echo Committing Auth...
git add "%FRONTEND_DIR%/lib/features/auth"
git add "%BACKEND_DIR%/Controllers/AuthController.cs"
git add "%BACKEND_DIR%/Services/AuthService.cs"
git add "%BACKEND_DIR%/Services/IAuthService.cs"
git add "%BACKEND_DIR%/Repositories/UserRepository.cs"
git add "%BACKEND_DIR%/Repositories/IUserRepository.cs"
git add "%BACKEND_DIR%/Models/User.cs"
git add "%BACKEND_DIR%/DTOs/SignInDto.cs"
git add "%BACKEND_DIR%/DTOs/SignUpDto.cs"
git add "%BACKEND_DIR%/DTOs/AuthResponseDto.cs"

set GIT_AUTHOR_DATE=2025-11-26T12:00:00
set GIT_COMMITTER_DATE=2025-11-26T12:00:00
git commit -m "feat(auth): Add authentication feature (login/signup) and related services"

REM ==========================================
REM 3. Agronomy Feature - 2025-12-02
REM ==========================================
echo Committing Agronomy...
git add "%FRONTEND_DIR%/lib/features/agronomy"
git add "%BACKEND_DIR%/*Agronomy*" 
git add "%BACKEND_DIR%/*Variety*" 
git add "%BACKEND_DIR%/*District*" 
git add "%BACKEND_DIR%/*Soil*" 
git add "%BACKEND_DIR%/*Pepper*" 
git add "%BACKEND_DIR%/*Emergency*" 
git add "%BACKEND_DIR%/*Guide*"
REM Add Task related DTOs here or in Sessions? Usually tasks are agronomy or plantation. Let's add them here.
git add "%BACKEND_DIR%/DTOs/CreateManualTaskDto.cs"
git add "%BACKEND_DIR%/DTOs/CompleteTaskDto.cs"
git add "%BACKEND_DIR%/DTOs/UpdateTaskDto.cs"
git add "%BACKEND_DIR%/DTOs/UpdateCompletionDetailsDto.cs"

set GIT_AUTHOR_DATE=2025-12-02T12:00:00
set GIT_COMMITTER_DATE=2025-12-02T12:00:00
git commit -m "feat(agronomy): Add agronomy modules"

REM ==========================================
REM 4. Plantation Feature - 2025-12-08
REM ==========================================
echo Committing Plantation...
git add "%FRONTEND_DIR%/lib/features/plantation"
git add "%BACKEND_DIR%/*Plantation*" 
git add "%BACKEND_DIR%/*Farm*"

set GIT_AUTHOR_DATE=2025-12-08T12:00:00
set GIT_COMMITTER_DATE=2025-12-08T12:00:00
git commit -m "feat(plantation): Add plantation modules"

REM ==========================================
REM 5. Seasons Feature - 2025-12-14
REM ==========================================
echo Committing Seasons...
git add "%FRONTEND_DIR%/lib/features/seasons"
git add "%BACKEND_DIR%/*Season*"

set GIT_AUTHOR_DATE=2025-12-14T12:00:00
set GIT_COMMITTER_DATE=2025-12-14T12:00:00
git commit -m "feat(seasons): Add season modules"

REM ==========================================
REM 6. Sessions Feature - 2025-12-20
REM ==========================================
echo Committing Sessions...
git add "%FRONTEND_DIR%/lib/features/sessions"
git add "%BACKEND_DIR%/*Session*"

set GIT_AUTHOR_DATE=2025-12-20T12:00:00
set GIT_COMMITTER_DATE=2025-12-20T12:00:00
git commit -m "feat(sessions): Add session tracking"

REM ==========================================
REM 7. Predictions Feature - 2025-12-28
REM ==========================================
echo Committing Predictions...
git add "%FRONTEND_DIR%/lib/features/predictions"
git add "%BACKEND_DIR%/*Prediction*"

set GIT_AUTHOR_DATE=2025-12-28T12:00:00
set GIT_COMMITTER_DATE=2025-12-28T12:00:00
git commit -m "feat(predictions): Add price prediction feature"

REM ==========================================
REM 8. Chat Feature - 2026-01-04
REM ==========================================
echo Committing Chat...
git add "%FRONTEND_DIR%/lib/features/chat"
git add "%BACKEND_DIR%/*Chat*" 
git add "%BACKEND_DIR%/*Embedding*" 
git add "%BACKEND_DIR%/*Context*"
git add "%BACKEND_DIR%/Services/KnowledgeRetrievalService.cs"

set GIT_AUTHOR_DATE=2026-01-04T12:00:00
set GIT_COMMITTER_DATE=2026-01-04T12:00:00
git commit -m "feat(chat): Add chat feature"

REM ==========================================
REM 9. Final Sweep - Commit Anything Left
REM ==========================================
echo Committing any remaining files...
git add .
set GIT_AUTHOR_DATE=2026-01-05T12:00:00
set GIT_COMMITTER_DATE=2026-01-05T12:00:00
git commit -m "chore: Add remaining project files and configurations"

echo Done! Run 'git log --oneline' to verify.
pause
