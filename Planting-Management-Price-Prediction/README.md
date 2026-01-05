# SKR Harvest Tracking System

A comprehensive harvest tracking and agronomy management system designed to help researchers and farmers monitor plantations, track harvests, and utilize AI-driven predictions.

## 📂 Folder Structure

The project is divided into two main components:

```
ResearchProject/
├── SKR-Backend-API/        # ASP.NET Core Web API Backend
│   ├── Config/            # Configuration files
│   ├── Controllers/       # API Endpoints
│   ├── Data/             # Database Context
│   ├── Models/           # Entity Models
│   ├── Services/         # Business Logic & ML Services
│   └── ...
│
├── SKR-Frontend-Mobile/    # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/         # Core utilities (Networking, Theme)
│   │   ├── features/     # Feature-based modules (Auth, Plantation, etc.)
│   │   └── main.dart     # App Entry point
│   └── ...
└── ...
```

## 🚀 Functions & Modules

The system is built around several key functional areas, mirrored in both the Backend API and Frontend App:

*   **Authentication (`Auth`)**: User registration, login, and secure token management (JWT).
*   **Plantations (`Plantation`)**: Management of plantation details, location data, and tracking.
*   **Agronomy (`Agronomy`)**: Monitoring of agricultural metrics, soil health, and crop status.
*   **Seasons (`Seasons`)**: Tracking growing seasons and harvest periods.
*   **Sessions (`Sessions`)**: Management of specific working or data collection sessions.
*   **Predictions (`Prediction`)**: AI/ML-powered price and yield predictions using ONNX models.
*   **Chat (`Chat`)**: Communication or AI assistant interface (PepperKnowledge).
*   **Knowledge Base (`PepperKnowledgeAdmin`)**: Administration of agricultural domain knowledge.

## 🏗️ Architecture

```mermaid
graph TD
    Client[Mobile App (Flutter)]
    API[Backend API (.NET 8)]
    DB[(PostgreSQL Database)]
    ML[ML Services (ONNX)]

    Client -->|HTTP/REST| API
    API -->|EF Core| DB
    API -->|Inference| ML
```

## 🛠️ Tech Stack

### Backend (`SKR-Backend-API`)
*   **Framework**: ASP.NET Core 8.0 (Web API)
*   **Database**: PostgreSQL
*   **ORM**: Entity Framework Core 8.0
*   **AI/ML**: Microsoft.ML.OnnxRuntime, OpenAI
*   **Authentication**: JWT Bearer
*   **Documentation**: Swagger / OpenAPI

### Frontend (`SKR-Frontend-Mobile`)
*   **Framework**: Flutter (Dart)
*   **State Management**: Flutter Riverpod
*   **Networking**: Dio, HTTP
*   **Local Storage**: Flutter Secure Storage, Shared Preferences
*   **Utilities**: Intl, UUID, Json Serializable

## ⚙️ Setup & Installation

### Prerequisites
*   .NET 8.0 SDK
*   Flutter SDK
*   PostgreSQL Server

### 1. Backend Setup
1.  Navigate to the backend directory:
    ```bash
    cd SKR-Backend-API
    ```
2.  Update the connection string in `appsettings.json` to point to your PostgreSQL instance.
3.  Apply database migrations:
    ```bash
    dotnet ef database update
    ```
4.  Run the API:
    ```bash
    dotnet run
    ```
    The API will usually start on `http://localhost:5270` or `https://localhost:7227` (check console output).

### 2. Frontend Setup
1.  Navigate to the frontend directory:
    ```bash
    cd SKR-Frontend-Mobile
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Configure the API Base URL in `lib/core/network/api_client.dart` (or equivalent config file) to match your backend URL.
    *   *Note: For Android Emulator, use `10.0.2.2` instead of `localhost`.*
    *   *Note: For Physical Device, use your machine's LAN IP.*
4.  Run the app:
    ```bash
    flutter run
    ```

## 📝 Commands Guide
For more specific commands, see:
*   [Backend Commands](BACKEND_API_COMMANDS.md)
*   [Flutter Commands](FLUTTER_COMMANDS.md)
