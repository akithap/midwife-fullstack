# Sequence Diagrams from Activity Flows

This document contains 4 sequence diagrams corresponding to the provided activity diagrams.

## 1. Overview Analytics for MOH (Website)

**Scenario**: MOH Staff logs in and views the Analytics Reports.

```mermaid
sequenceDiagram
    autonumber
    actor MOH as MOH Staff
    participant Web as MOH Website (Frontend)
    participant API as Backend API
    participant DB as Database

    Note over MOH, Web: User Logic
    MOH->>Web: Open Website & Enter Credentials
    Web->>API: POST /moh/token (username, password)
    activate API
    API->>DB: Validate MOH Credentials
    DB-->>API: Result
    
    alt Validation Failed
        API-->>Web: 401 Unauthorized
        Web-->>MOH: Display Error Message
    else Validation Success
        API-->>Web: 200 OK (Token)
        Web-->>MOH: Display Dashboard
    end
    deactivate API

    MOH->>Web: Click "Reports" on Menu Bar
    activate Web
    Web->>API: GET /moh/analytics/ (Hotspots/Stats)
    activate API
    API->>DB: Query Aggregated Data
    DB-->>API: Return Data
    API-->>Web: JSON Analytics Data
    deactivate API
    Web-->>MOH: Show Analytics Dashboard
    deactivate Web
```

## 2. Location Map for Midwife (Mobile)

**Scenario**: Midwife logins and accesses the Map feature to view mother locations.

```mermaid
sequenceDiagram
    autonumber
    actor Midwife
    participant App as Mobile App (Frontend)
    participant API as Backend API
    participant DB as Database

    Midwife->>App: Open App
    Midwife->>App: Login(username, password)
    activate App
    App->>API: POST /token
    activate API
    
    API->>DB: Validate Midwife
    DB-->>API: Valid
    API-->>App: 200 OK (Token)
    deactivate API
    
    App-->>Midwife: View Dashboard
    deactivate App

    Midwife->>App: Click "Map" (Bottom Nav)
    activate App
    App->>API: GET /mothers/ (Fetch Locations)
    activate API
    API->>DB: Query Mothers with Lat/Lng
    DB-->>API: Return Mothers List
    API-->>App: List[Mother]
    deactivate API
    
    App->>App: Render Markers on Map
    App-->>Midwife: Load Map Interface
    deactivate App
```

## 3. Communication / Texting (Mobile)

**Scenario**: Midwife selects a mother and opens the chat screen.

```mermaid
sequenceDiagram
    autonumber
    actor Midwife
    participant App as Mobile App
    participant API as Backend API
    participant DB as Database

    %% Assuming User is already logged in (based on diagram flow jumping to Dashboard)
    Note over Midwife, App: Pre-condition: Logged In
    
    Midwife->>App: View Dashboard
    Midwife->>App: Select "Mothers" (Bottom Nav)
    activate App
    App->>API: GET /mothers/
    activate API
    API->>DB: Fetch Assigned Mothers
    DB-->>API: Return List
    API-->>App: Display Mothers List
    deactivate API
    deactivate App

    Midwife->>App: Click Message Icon (Specific Mother)
    activate App
    App->>API: GET /midwives/messages/{mother_id}
    activate API
    API->>DB: Fetch Chat History
    DB-->>API: Return Messages
    API-->>App: JSON Message List
    deactivate API
    
    App-->>Midwife: Open Chat Screen
    deactivate App
```

## 4. MOH Website Dashboard (Login)

**Scenario**: Standard Login flow for the MOH Website.

```mermaid
sequenceDiagram
    autonumber
    actor User as MOH User
    participant Web as Website UI
    participant API as Backend API
    participant DB as Database

    User->>Web: Open Website
    User->>Web: Login(username, password)
    activate Web
    
    Web->>API: POST /moh/token
    activate API
    API->>DB: Check Credentials
    
    alt Login Fail
        DB-->>API: Invalid / Not Found
        API-->>Web: 401 Error
        Web-->>User: Display Error Message
        Note right of Web: Retry Login
    else Login Successful
        DB-->>API: Valid
        API-->>Web: 200 OK (Auth Token)
        Web->>API: GET /moh/dashboard/stats
        API->>DB: Fetch Dashboard Stats
        DB-->>API: Stats Data
        API-->>Web: Return Stats
        Web-->>User: View Dashboard
    end
    deactivate API
    deactivate Web
```
