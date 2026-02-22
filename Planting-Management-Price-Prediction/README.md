# SKR Harvest Tracking System

A comprehensive harvest tracking and agronomy management system designed to help researchers and farmers monitor plantations, track harvests, and utilize AI-driven predictions.

## 📂 Folder Structure

The project is divided into two main components:

```
ResearchProject/
├── plantationmanagement/    # Node.js (Express) Backend
│   ├── src/
│   │   ├── config/         # Database & Firebase config
│   │   ├── controllers/    # API Request Handlers
│   │   ├── models/         # Sequelize Models
│   │   ├── routes/         # API Routes
│   │   ├── services/       # Business Logic & AI Services
│   │   └── utils/          # Helper functions
│   ├── rag_data/           # RAG documentation and data
│   └── ...
│
├── SKR-Frontend-Mobile/    # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/           # Core utilities (Networking, Theme)
│   │   ├── features/       # Feature-based modules (Auth, Plantation, etc.)
│   │   └── main.dart       # App Entry point
│   └── ...
└── ...
```

## 🚀 Functions & Modules

The system is built around several key functional areas:

*   **Authentication (`Auth`)**: User registration, login, and secure token management (JWT).
*   **Plantations (`Plantation`)**: Management of plantation details, location data, and tracking.
*   **Agronomy (`Agronomy`)**: Monitoring of agricultural metrics, soil health, and crop status.
*   **Seasons (`Seasons`)**: Tracking growing seasons and harvest periods.
*   **Sessions (`Sessions`)**: Management of specific working or data collection sessions.
*   **Predictions (`Prediction`)**: AI/ML-powered price and yield predictions using ONNX models.
*   **Chat (`Chat`)**: Communication or AI assistant interface (RAG-powered).

## 🏗️ Architecture

```mermaid
graph TD
    Client[Mobile App (Flutter)]
    API[Backend API (Node.js/Express)]
    DB[(PostgreSQL Database)]
    AI[AI/ML Services (ONNX, OpenAI)]

    Client -->|HTTP/REST| API
    API -->|Sequelize| DB
    API -->|Inference| AI
```

## 🛠️ Tech Stack

### Backend (`plantationmanagement`)
*   **Framework**: Node.js (Express)
*   **Database**: PostgreSQL
*   **ORM**: Sequelize
*   **AI/ML**: ONNX Runtime, OpenAI (for RAG)
*   **Authentication**: JWT & Firebase Admin SDK
*   **Documentation**: REST API Architecture

### Frontend (`SKR-Frontend-Mobile`)
*   **Framework**: Flutter (Dart)
*   **State Management**: Flutter Riverpod
*   **Networking**: Dio, HTTP
*   **Local Storage**: Flutter Secure Storage, Shared Preferences

## ⚙️ Setup & Installation

### Prerequisites
*   Node.js (v18 or higher)
*   Flutter SDK
*   PostgreSQL Server

### 1. Backend Setup
1.  Navigate to the backend directory:
    ```bash
    cd plantationmanagement
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Create a `.env` file with your database and API credentials.
4.  Run the API:
    ```bash
    npm run dev
    ```
    The API will usually start on `http://localhost:7001`.

### 2. Frontend Setup
1.  Navigate to the frontend directory:
    ```bash
    cd SKR-Frontend-Mobile
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Configure the API Base URL in `lib/core/network/api_client.dart` to `http://localhost:7001`.
    *   *Note: For Android Emulator, use `10.0.2.2` instead of `localhost`.*
4.  Run the app:
    ```bash
    flutter run
    ```

## 📝 Commands Guide
For more specific commands, see:
*   [Backend Commands](BACKEND_API_COMMANDS.md)
*   [Flutter Commands](FLUTTER_COMMANDS.md)
