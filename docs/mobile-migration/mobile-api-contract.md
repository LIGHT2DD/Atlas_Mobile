# ATLAS Mobile REST API Specification (v1)
**Base Path:** `/api/mobile/v1`  
**Security Scheme:** HTTP Bearer JWT (`Authorization: Bearer <access_token>`)

---

## 1. Global Response Envelope & Status Codes

All `/api/mobile/v1/` endpoints adhere to a standardized JSON response structure:

### Success Envelope
```json
{
  "success": true,
  "status_code": 200,
  "message": "Operation completed successfully.",
  "data": { ... }
}
```

### Error Envelope
```json
{
  "success": false,
  "status_code": 400,
  "message": "Human readable explanation of failure.",
  "errors": [
    "Specific validation detail or field error"
  ]
}
```

### Standard Status Codes
- `200 OK`: Request succeeded.
- `201 Created`: Resource successfully created.
- `400 Bad Request`: Business rule violation (e.g., student already in an active team, quota reached).
- `401 Unauthorized`: Missing, expired, or invalid Bearer token.
- `403 Forbidden`: Authenticated user lacks required role or resource ownership.
- `404 Not Found`: Target entity does not exist.
- `409 Conflict`: Scheduling conflict or unique constraint collision.
- `422 Unprocessable Entity`: Request body failed Pydantic schema validation.
- `500 Internal Server Error`: Unhandled server exception.

---

## 2. Authentication & Session Endpoints

### 2.1 Login
- **Endpoint:** `POST /api/mobile/v1/auth/login`
- **Auth:** Public
- **Request Body:**
  ```json
  {
    "email": "student1@atlas.edu",
    "password": "Password123"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "status_code": 200,
    "message": "Logged in successfully",
    "data": {
      "access_token": "eyJhbGciOi...",
      "refresh_token": "eyJhbGciOi...",
      "token_type": "bearer",
      "user": {
        "id": "uuid",
        "email": "student1@atlas.edu",
        "first_name": "Tahmid",
        "last_name": "Hasan",
        "role": "student",
        "avatar_url": null,
        "is_active": true
      }
    }
  }
  ```

### 2.2 Token Refresh
- **Endpoint:** `POST /api/mobile/v1/auth/refresh`
- **Auth:** Public (Requires refresh token in payload)
- **Request Body:**
  ```json
  {
    "refresh_token": "eyJhbGciOi..."
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "status_code": 200,
    "message": "Tokens refreshed",
    "data": {
      "access_token": "eyJhbGciOi...",
      "refresh_token": "eyJhbGciOi...",
      "token_type": "bearer"
    }
  }
  ```

### 2.3 Logout
- **Endpoint:** `POST /api/mobile/v1/auth/logout`
- **Auth:** Bearer Token (Any Role)
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "status_code": 200,
    "message": "Logged out successfully"
  }
  ```

### 2.4 Current User Profile & Context
- **Endpoint:** `GET /api/mobile/v1/auth/me`
- **Auth:** Bearer Token (Any Role)
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "status_code": 200,
    "message": "Profile retrieved",
    "data": {
      "user": { ... },
      "active_team": { ... },
      "active_semester": { ... }
    }
  }
  ```

---

## 3. Team Management Endpoints

### 3.1 Get Student's Active Team
- **Endpoint:** `GET /api/mobile/v1/teams/my-team`
- **Auth:** Bearer Token (`student`)
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "status_code": 200,
    "data": {
      "has_team": true,
      "team": {
        "id": "uuid",
        "name": "Neural Nexus",
        "project_title": "Edge AI",
        "status": "supervisor_assigned",
        "invite_code": "K9Q_mZ81",
        "leader_id": "uuid",
        "supervisor": { "id": "uuid", "name": "Fatema Jannat Dihan", "email": "supervisor1@atlas.edu" },
        "members": [ ... ]
      }
    }
  }
  ```

### 3.2 Create Team
- **Endpoint:** `POST /api/mobile/v1/teams`
- **Auth:** Bearer Token (`student`)
- **Request Body:**
  ```json
  {
    "name": "Apollo Mission",
    "project_title": "Autonomous Systems",
    "semester_id": "uuid",
    "description": "Optional research scope"
  }
  ```

### 3.3 Join Team via Invite Code
- **Endpoint:** `POST /api/mobile/v1/teams/join`
- **Auth:** Bearer Token (`student`)
- **Request Body:**
  ```json
  {
    "invite_code": "K9Q_mZ81"
  }
  ```

### 3.4 Request Supervisor
- **Endpoint:** `POST /api/mobile/v1/teams/{team_id}/request-supervisor`
- **Auth:** Bearer Token (`student` - Leader only)
- **Request Body:**
  ```json
  {
    "supervisor_id": "uuid",
    "notes": "Research pitch and methodology"
  }
  ```

---

## 4. Proposal Lifecycle Endpoints

### 4.1 Submit Proposal / Revision
- **Endpoint:** `POST /api/mobile/v1/proposals/submit`
- **Auth:** Bearer Token (`student` - Team Leader)
- **Request Format:** Multipart form data or JSON
  - `team_id`: string
  - `title`: string
  - `abstract`: string
  - `file`: optional PDF binary upload

### 4.2 Review Proposal
- **Endpoint:** `POST /api/mobile/v1/proposals/{proposal_id}/review`
- **Auth:** Bearer Token (`supervisor` - Assigned)
- **Request Body:**
  ```json
  {
    "decision": "approved", // or "changes_requested" or "rejected"
    "comments": "Detailed critique or directives"
  }
  ```

---

## 5. Milestone & Deliverable Endpoints

### 5.1 List Milestones
- **Endpoint:** `GET /api/mobile/v1/milestones`
- **Auth:** Bearer Token (Any Role)
- **Response:** List of milestones with due dates, weights, max scores, and submission flags.

### 5.2 Submit Deliverable
- **Endpoint:** `POST /api/mobile/v1/submissions`
- **Auth:** Bearer Token (`student`)
- **Request Format:** Multipart form data
  - `milestone_id`: string
  - `team_id`: string
  - `title`: string
  - `code_url`: string (e.g. GitHub link)
  - `file`: optional PDF deliverable

### 5.3 Grade Submission
- **Endpoint:** `POST /api/mobile/v1/submissions/{submission_id}/grade`
- **Auth:** Bearer Token (`supervisor`)
- **Request Body:**
  ```json
  {
    "score": 94.5,
    "feedback_text": "Strong technical execution."
  }
  ```

---

## 6. Oral Defense & Conflict Prevention

### 6.1 Schedule Defense
- **Endpoint:** `POST /api/mobile/v1/defenses/schedule`
- **Auth:** Bearer Token (`coordinator`, `admin`)
- **Request Body:**
  ```json
  {
    "team_id": "uuid",
    "scheduled_date": "2026-11-20",
    "start_time": "10:00",
    "end_time": "11:00",
    "venue": "Conference Hall A",
    "panelist_ids": ["uuid-faculty-1", "uuid-faculty-2"]
  }
  ```
- **Error Response `409 Conflict`:**
  Returned when room is already booked or a panelist has a double-booking.

---

## 7. Rubrics, Evaluation & Grade Publishing

### 7.1 Submit Rubric Evaluation
- **Endpoint:** `POST /api/mobile/v1/evaluations/{team_id}`
- **Auth:** Bearer Token (`supervisor`, `coordinator`)
- **Request Body:**
  ```json
  {
    "rubric_scores": [
      { "criteria_id": "uuid-1", "score": 28.0 },
      { "criteria_id": "uuid-2", "score": 19.0 }
    ],
    "remarks": "Exemplary oral defense and system demo."
  }
  ```

### 7.2 Publish Final Grades
- **Endpoint:** `POST /api/mobile/v1/grades/{team_id}/publish`
- **Auth:** Bearer Token (`coordinator`, `admin`)
- **Request Body:**
  ```json
  {
    "final_grade": "A+",
    "final_score": 92.5
  }
  ```

---

## 8. Notifications & FCM

### 8.1 Register Device FCM Token
- **Endpoint:** `POST /api/mobile/v1/notifications/device-token`
- **Auth:** Bearer Token (Any Role)
- **Request Body:**
  ```json
  {
    "fcm_token": "fcm_device_token_string",
    "device_type": "android"
  }
  ```

### 8.2 Get Notifications
- **Endpoint:** `GET /api/mobile/v1/notifications`
- **Auth:** Bearer Token (Any Role)
- **Response:** List of notifications, read states, creation dates, and action links.
