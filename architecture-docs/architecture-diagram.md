# Architecture Diagrams

**Part of:** [ARCHITECTURE.md](./ARCHITECTURE.md) - Complete system design and integration patterns

This document provides visual representations of HackTracker's architecture using both Mermaid diagrams (for detailed views) and ASCII diagrams (for quick reference).

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Data Flow Diagrams](#data-flow-diagrams)
3. [Authentication Flow](#authentication-flow)
4. [State Management Flow](#state-management-flow)
5. [ASCII Diagrams](#ascii-diagrams)

---

## System Overview

### Complete System Architecture

```mermaid
graph TB
    subgraph "Frontend Layer"
        FA[Flutter App<br/>iOS/Android/Web]
        FA --> AUTH[Amplify Auth Cognito]
        FA --> STATE[Riverpod 3.0<br/>State Management]
        FA --> CACHE[Shared Preferences<br/>Persistent Cache]
        FA --> API[HTTP Client<br/>JWT Authentication]
    end
    
    subgraph "API Layer"
        AG[API Gateway<br/>HTTP API]
        AG --> JWT[JWT Authorizer<br/>Cognito]
        AG --> CORS[CORS Configuration]
        AG --> ROUTES[15 Endpoints<br/>User/Team/Player CRUD]
    end
    
    subgraph "Lambda Layer"
        subgraph "User Management"
            UC[create-user<br/>Cognito Trigger]
            UG[get-user]
            UQ[query-users]
            UU[update-user]
            UD[delete-user]
        end
        
        subgraph "Team Management"
            TC[create-team]
            TG[get-team]
            TQ[query-teams]
            TU[update-team]
            TD[delete-team]
        end
        
        subgraph "Player Management"
            PA[add-player]
            PL[list-players]
            PG[get-player]
            PU[update-player]
            PR[remove-player]
        end
        
        subgraph "Shared Utils"
            AUTH_UTIL[authorization.py<br/>v2 Policy Engine]
            VAL_UTIL[validation.py]
            DB_UTIL[dynamodb.py<br/>Global Client]
            API_UTIL[api_gateway.py]
        end
    end
    
    subgraph "Data Layer"
        DB[(DynamoDB<br/>Single Table)]
        DB --> GSI1[GSI1<br/>Cognito Sub Lookup]
        DB --> GSI2[GSI2<br/>Entity Listing]
        DB --> GSI3[GSI3-5<br/>Reserved]
        
        COGNITO[(Cognito User Pool)]
        COGNITO --> JWT_TOKENS[JWT Tokens]
        COGNITO --> TRIGGER[Post-Confirmation<br/>Trigger]
    end
    
    %% Connections
    API --> AG
    AG --> UC
    AG --> UG
    AG --> UQ
    AG --> UU
    AG --> UD
    AG --> TC
    AG --> TG
    AG --> TQ
    AG --> TU
    AG --> TD
    AG --> PA
    AG --> PL
    AG --> PG
    AG --> PU
    AG --> PR
    
    UC --> DB
    UG --> DB
    UQ --> DB
    UU --> DB
    UD --> DB
    TC --> DB
    TG --> DB
    TQ --> DB
    TU --> DB
    TD --> DB
    PA --> DB
    PL --> DB
    PG --> DB
    PU --> DB
    PR --> DB
    
    TRIGGER --> UC
    AUTH --> COGNITO
    JWT --> COGNITO
    
    %% Styling
    classDef frontend fill:#14D68E,stroke:#0F172A,stroke-width:2px,color:#0F172A
    classDef api fill:#4AE4A8,stroke:#0F172A,stroke-width:2px,color:#0F172A
    classDef lambda fill:#1E293B,stroke:#14D68E,stroke-width:2px,color:#E2E8F0
    classDef data fill:#334155,stroke:#14D68E,stroke-width:2px,color:#E2E8F0
    
    class FA,AUTH,STATE,CACHE,API frontend
    class AG,JWT,CORS,ROUTES api
    class UC,UG,UQ,UU,UD,TC,TG,TQ,TU,TD,PA,PL,PG,PU,PR,AUTH_UTIL,VAL_UTIL,DB_UTIL,API_UTIL lambda
    class DB,GSI1,GSI2,GSI3,COGNITO,JWT_TOKENS,TRIGGER data
```

---

## Data Flow Diagrams

### Request Flow (User Action to Response)

```mermaid
sequenceDiagram
    participant U as User
    participant F as Flutter App
    participant AG as API Gateway
    participant L as Lambda Function
    participant D as DynamoDB
    participant C as Cache
    
    Note over U,C: User Action Flow
    
    U->>F: User Action (e.g., Create Team)
    F->>F: Optimistic UI Update
    F->>F: Show Loading State
    
    F->>AG: HTTP Request (JWT Token)
    AG->>AG: Validate JWT Token
    AG->>L: Invoke Lambda
    
    L->>L: Extract userId from JWT
    L->>L: Validate Input
    L->>L: Check Authorization
    L->>D: DynamoDB Transaction
    D-->>L: Success Response
    L-->>AG: API Response (201 Created)
    AG-->>F: HTTP Response
    
    F->>F: Update Cache
    F->>F: Update UI with Real Data
    F->>U: Show Success Message
    
    Note over U,C: Error Handling
    
    alt API Error
        L-->>AG: Error Response (4xx/5xx)
        AG-->>F: HTTP Error
        F->>F: Rollback Optimistic Update
        F->>U: Show Error Message
    end
```

### Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant F as Flutter App
    participant C as Cognito
    participant AG as API Gateway
    participant L as Lambda
    
    Note over U,L: Authentication Flow
    
    U->>F: Sign In (Email/Password)
    F->>C: Authenticate User
    C-->>F: JWT Tokens (ID, Access, Refresh)
    
    F->>F: Store Tokens
    F->>F: Validate Token Expiration
    F->>F: Navigate to Home Screen
    
    Note over U,L: API Request Flow
    
    F->>AG: API Request + JWT Token
    AG->>AG: Validate JWT Signature
    AG->>AG: Check Token Expiration
    AG->>AG: Extract User Claims
    
    alt Valid Token
        AG->>L: Forward Request + User Context
        L->>L: Process Request
        L-->>AG: Response
        AG-->>F: API Response
    else Invalid/Expired Token
        AG-->>F: 401 Unauthorized
        F->>F: Sign Out User
        F->>F: Navigate to Login
    end
```

### Caching Strategy Flow

```mermaid
sequenceDiagram
    participant F as Flutter App
    participant C as Cache (Shared Preferences)
    participant AG as API Gateway
    participant L as Lambda
    participant D as DynamoDB
    
    Note over F,D: App Launch Flow
    
    F->>C: Load Cached Data
    C-->>F: Return Cached Data (if exists)
    
    alt Cache Hit
        F->>F: Display Cached Data Immediately
        F->>AG: Background Refresh Request
        AG->>L: Invoke Lambda
        L->>D: Query DynamoDB
        D-->>L: Fresh Data
        L-->>AG: API Response
        AG-->>F: Fresh Data
        F->>C: Update Cache
        F->>F: Update UI with Fresh Data
    else Cache Miss
        F->>AG: API Request
        AG->>L: Invoke Lambda
        L->>D: Query DynamoDB
        D-->>L: Data
        L-->>AG: API Response
        AG-->>F: Data
        F->>C: Store in Cache
        F->>F: Display Data
    end
    
    Note over F,D: Error Handling
    
    alt API Error
        AG-->>F: Error Response
        F->>F: Keep Cached Data (if available)
        F->>F: Show Error Message
    end
```

---

## Authentication Flow

### Complete Authentication Architecture

```mermaid
graph LR
    subgraph "Client Side"
        APP[Flutter App]
        AUTH_SERVICE[AuthService]
        AMPLIFY[Amplify Auth]
    end
    
    subgraph "AWS Cognito"
        USER_POOL[Cognito User Pool]
        CLIENT[User Pool Client]
        DOMAIN[Cognito Domain]
    end
    
    subgraph "API Security"
        API_GATEWAY[API Gateway]
        JWT_AUTH[JWT Authorizer]
    end
    
    subgraph "Lambda Security"
        LAMBDA[Lambda Functions]
        USER_CONTEXT[User Context<br/>from JWT]
    end
    
    %% Authentication Flow
    APP --> AUTH_SERVICE
    AUTH_SERVICE --> AMPLIFY
    AMPLIFY --> USER_POOL
    USER_POOL --> CLIENT
    CLIENT --> DOMAIN
    
    %% Token Flow
    USER_POOL --> JWT_TOKENS[JWT Tokens<br/>ID/Access/Refresh]
    JWT_TOKENS --> APP
    
    %% API Request Flow
    APP --> API_GATEWAY
    API_GATEWAY --> JWT_AUTH
    JWT_AUTH --> USER_POOL
    JWT_AUTH --> LAMBDA
    LAMBDA --> USER_CONTEXT
    
    %% Styling
    classDef client fill:#14D68E,stroke:#0F172A,stroke-width:2px,color:#0F172A
    classDef cognito fill:#4AE4A8,stroke:#0F172A,stroke-width:2px,color:#0F172A
    classDef api fill:#1E293B,stroke:#14D68E,stroke-width:2px,color:#E2E8F0
    classDef lambda fill:#334155,stroke:#14D68E,stroke-width:2px,color:#E2E8F0
    
    class APP,AUTH_SERVICE,AMPLIFY client
    class USER_POOL,CLIENT,DOMAIN,JWT_TOKENS cognito
    class API_GATEWAY,JWT_AUTH api
    class LAMBDA,USER_CONTEXT lambda
```

---

## State Management Flow

### Riverpod State Management Architecture

```mermaid
graph TB
    subgraph "UI Layer"
        WIDGET[Flutter Widgets]
        CONSUMER[Consumer Widgets]
    end
    
    subgraph "State Management"
        PROVIDER[Riverpod Providers]
        ASYNC_NOTIFIER[AsyncNotifier]
        STATE_PROVIDER[StateProvider]
        FAMILY_PROVIDER[Family Provider]
    end
    
    subgraph "Data Layer"
        CACHE[Shared Preferences<br/>Persistent Cache]
        API[API Service]
        PERSISTENCE[Persistence Utils]
    end
    
    subgraph "External Services"
        API_GATEWAY[API Gateway]
        DYNAMODB[DynamoDB]
    end
    
    %% Data Flow
    WIDGET --> CONSUMER
    CONSUMER --> PROVIDER
    PROVIDER --> ASYNC_NOTIFIER
    PROVIDER --> STATE_PROVIDER
    PROVIDER --> FAMILY_PROVIDER
    
    ASYNC_NOTIFIER --> CACHE
    ASYNC_NOTIFIER --> API
    API --> API_GATEWAY
    API_GATEWAY --> DYNAMODB
    
    CACHE --> PERSISTENCE
    
    %% Optimistic Updates
    ASYNC_NOTIFIER -.->|Optimistic Update| CONSUMER
    ASYNC_NOTIFIER -.->|Rollback on Error| CONSUMER
    
    %% Styling
    classDef ui fill:#14D68E,stroke:#0F172A,stroke-width:2px,color:#0F172A
    classDef state fill:#4AE4A8,stroke:#0F172A,stroke-width:2px,color:#0F172A
    classDef data fill:#1E293B,stroke:#14D68E,stroke-width:2px,color:#E2E8F0
    classDef external fill:#334155,stroke:#14D68E,stroke-width:2px,color:#E2E8F0
    
    class WIDGET,CONSUMER ui
    class PROVIDER,ASYNC_NOTIFIER,STATE_PROVIDER,FAMILY_PROVIDER state
    class CACHE,API,PERSISTENCE data
    class API_GATEWAY,DYNAMODB external
```

---

## ASCII Diagrams

### Quick Reference Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        HackTracker Architecture                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   API Gateway   │    │ Lambda Functions│
│                 │    │                 │    │                 │
│ • iOS/Android   │───▶│ • HTTP API      │───▶│ • User CRUD     │
│ • Web           │    │ • JWT Auth      │    │ • Team CRUD     │
│ • Riverpod 3.0  │    │ • CORS          │    │ • Player CRUD  │
│ • Persistent    │    │ • 15 Routes     │    │ • v2 Policy    │
│   Cache         │    │                 │    │   Engine        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cognito       │    │   DynamoDB      │    │   Shared        │
│   User Pool     │    │   Single Table  │    │   Preferences   │
│                 │    │                 │    │                 │
│ • JWT Tokens    │    │ • PK/SK Design  │    │ • Cache v1.0.0  │
│ • Post-Confirm  │    │ • GSI1-5        │    │ • SWR Pattern   │
│   Trigger       │    │ • Personal      │    │ • Optimistic    │
│                 │    │   Teams         │    │   Updates       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Request Flow

```
User Action → Flutter UI → Optimistic Update
     ↓
API Call (JWT) → API Gateway → JWT Authorizer
     ↓
Lambda → authorize() → DynamoDB
     ↓
Response → Update Cache → Update UI
```

### Authentication Flow

```
App Launch → Token Validation → Valid?
     ↓ Yes                    ↓ No
Home Screen              Login Screen
     ↓
API Request → JWT Token → API Gateway
     ↓
Lambda → Extract User → Process Request
```

### State Management Flow

```
UI Widget → Consumer → Provider → AsyncNotifier
     ↓
Cache Check → Show Cached → Background Refresh
     ↓
API Call → Update Cache → Update UI
```

### Data Model Overview

```
DynamoDB Single Table Design:

PK (Partition Key)          SK (Sort Key)           Entity Type
─────────────────          ──────────────          ────────────
USER#<userId>              METADATA                User Profile
USER#<userId>              TEAM#<teamId>           Team Membership
TEAM#<teamId>              METADATA                Team Profile
TEAM#<teamId>              PLAYER#<playerId>       Player Profile

Global Secondary Indexes:
GSI1: COGNITO#<sub>        USER                    User Lookup
GSI2: ENTITY#<type>        METADATA#<id>          Entity Listing
GSI3-5: Reserved for future features
```

### Lambda Function Overview

```
User Management (5 functions):
├── create-user    (Cognito Trigger)
├── get-user       (GET /users/{userId})
├── query-users    (GET /users)
├── update-user    (PUT /users/{userId})
└── delete-user    (DELETE /users/{userId})

Team Management (5 functions):
├── create-team    (POST /teams)
├── get-team       (GET /teams/{teamId})
├── query-teams    (GET /teams)
├── update-team    (PUT /teams/{teamId})
└── delete-team    (DELETE /teams/{teamId})

Player Management (5 functions):
├── add-player     (POST /teams/{teamId}/players)
├── list-players   (GET /teams/{teamId}/players)
├── get-player     (GET /teams/{teamId}/players/{playerId})
├── update-player  (PUT /teams/{teamId}/players/{playerId})
└── remove-player  (DELETE /teams/{teamId}/players/{playerId})
```

---

## Technology Stack Summary

### Frontend
- **Framework:** Flutter 3.9+ with Dart 3.9+
- **State Management:** Riverpod 3.0+
- **Authentication:** AWS Amplify Auth Cognito
- **Caching:** Shared Preferences with SWR pattern
- **UI:** Material 3 with custom theming

### Backend
- **API:** AWS API Gateway HTTP API
- **Functions:** AWS Lambda (Python 3.13, ARM64)
- **Database:** DynamoDB Single Table Design
- **Authentication:** Cognito JWT Authorizer
- **Infrastructure:** Terraform

### Key Features
- **Optimistic UI:** Race-condition-safe updates
- **Persistent Caching:** Session-retained data
- **Authorization:** v2 Policy Engine
- **Personal Teams:** Auto-created for each user
- **Global DynamoDB Client:** Warm-start optimization

---

## Summary

These diagrams provide comprehensive visual representations of HackTracker's architecture:

- **System Overview:** Complete system architecture with all components
- **Data Flow:** Request/response patterns and error handling
- **Authentication:** JWT-based security flow
- **State Management:** Riverpod patterns and caching strategy
- **ASCII Diagrams:** Quick reference for common patterns

The architecture supports **scalable development** with **clear separation of concerns** and **robust error handling** while maintaining **performance** and **user experience** standards.
