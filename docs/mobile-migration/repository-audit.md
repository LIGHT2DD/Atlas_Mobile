# ATLAS Repository Audit Report
**Date:** October 2026  
**System:** Academic Thesis Lifecycle & Assessment Suite (ATLAS)  
**Target:** Flutter Android Application Migration & Versioned Mobile REST API

---

## 1. Executive Summary

ATLAS is an institutional academic management system that governs the complete lifecycle of university capstone projects and research theses. The existing platform is implemented as a full-stack Python application using **FastAPI**, **SQLAlchemy**, **Alembic**, and **Jinja2** HTML templates, with authentication backed by **JWT** and session cookies, and optional **Firebase Storage** integration.

This audit establishes the baseline for building a dedicated Flutter Android client communicating via `/api/mobile/v1/` while preserving the existing web frontend and business logic untouched.

---

## 2. Directory Structure Analysis

```text
Atlas/
├── main.py                     # FastAPI entrypoint, middleware, exception handlers, router mounts
├── api/
│   ├── core/
│   │   └── dependencies/       # AuthMiddleware, CSRF verification, flash messages, email service
│   ├── db/
│   │   └── database.py         # SQLAlchemy engine, sessionmaker, scoped_session, get_db
│   ├── utils/                  # Settings, loggers, responses, paginator, firebase_service
│   └── v1/
│       ├── models/             # 20 SQLAlchemy declarative models
│       ├── routes/
│       │   ├── auth.py         # Web authentication portal & form handlers
│       │   ├── user.py         # User administration handlers
│       │   ├── external.py     # Public invite landing endpoints
│       │   ├── errors.py       # Custom error routes
│       │   └── dashboard/      # 20 role-based web dashboard sub-routers
│       ├── schemas/            # Pydantic validation schemas
│       └── services/           # 17 domain business services
├── alembic/                    # Database migration environment
│   └── versions/               # 230fa9a1cb9d_atlas_core_models.py
├── frontend/                   # Web Jinja2 templates (app/) and static CSS/JS assets
├── filestorage/                # Local persistent deliverable & document repository
├── tests/                      # Pytest automated test suite (17 comprehensive unit/integration tests)
└── credentials.txt             # Seeded test user roster across all lifecycle stages
```

---

## 3. Technology Stack & Database Verification

### 3.1 Backend & Server
- **Language / Framework:** Python 3.13 / 3.14, FastAPI 0.115+
- **ORM:** SQLAlchemy 2.0+ (Declarative base, scoped sessions)
- **ASGI Server:** Uvicorn with auto-reload and multiprocessing worker configuration
- **Settings:** Pydantic-settings / python-decouple reading `.env`

### 3.2 Database Engine & Configuration
- **Active Local DB:** SQLite 3 (`atlas.db` in workspace root, pre-populated with realistic thesis lifecycle stages)
- **Production Configuration:** PostgreSQL support via `DB_URL` environment variable (`postgresql://...`) in `api/db/database.py` and `docker-compose.yml`.
- **Migrations:** Alembic (`alembic.ini`) with baseline migration `230fa9a1cb9d_atlas_core_models.py` registering all core tables.

### 3.3 Security & Session Handling
- **Passwords:** Bcrypt hashing with salted CryptContext.
- **Tokens:** JSON Web Tokens (JWT) signed with HMAC-SHA256 (`HS256`), configurable `SECRET_KEY`.
- **Token Management:** Dedicated `tokens` table with token type differentiation (`access`, `refresh`, `magic`, `password_reset`), issued expiration timestamps, and `blacklisted_tokens` table for revocation on logout.
- **CSRF & Protection:** Double Submit Cookie and Origin verification via `verify_csrf_request()`. Programmatic API clients sending `Authorization: Bearer <token>` are explicitly whitelisted and exempt from CSRF checks.

### 3.4 Storage & Firebase Integration
- **Local Storage:** `DocumentService` stores files in `filestorage/` using UUID-prefixed secure filenames.
- **Firebase Admin SDK:** `FirebaseService` (`api/utils/firebase_service.py`) connects to Firebase Storage bucket using `firebase_config.py` and `serviceAccount.json`. Uploaded files are duplicated to the Firebase bucket when credentials are configured, updating the `file_url` property.

---

## 4. Current Test Suite Baseline

Pytest executed on `.venv`:
- **17 tests collected, 17 tests passed (100% success rate)**
- `test_auth_rbac.py`: Validates user authentication, invalid credentials, student blocked from coordinator rubrics (403), supervisor blocked from semester management (403), and student registration.
- `test_defense_conflict.py`: Validates defense schedule conflict engine (preventing room double-booking and faculty double-booking).
- `test_evaluations_rubrics.py`: Validates rubric criteria creation, weighted scoring calculation, and final grade publication.
- `test_milestones_submissions.py`: Validates on-time submission, server-side late submission detection, and supervisor grading.
- `test_proposals.py`: Validates proposal submission, revision requests, resubmission tracking, and approval lifecycle.
- `test_teams.py`: Validates team formation, single active team constraint, invite code joining, capacity enforcement, supervisor request, and supervisor approval.

---

## 5. Architectural Findings for Mobile API

1. **Exception Handler Adaptations:** In `main.py`, standard exception handlers catch `HTTPException`, `RequestValidationError`, and `IntegrityError`, returning `RedirectResponse` with flash messages for browser sessions. For paths starting with `/api/`, the exception handlers must return standard JSON responses with appropriate HTTP error codes (`400`, `401`, `403`, `404`, `422`, `500`).
2. **Bearer Token Authentication in Middleware:** `AuthMiddleware` currently checks cookies `access_token` and `refresh_token`. It should also check the `Authorization: Bearer <token>` header, allowing `request.state.current_user` to be transparently set for API requests.
3. **Dedicated Mobile API Router:** The new mobile endpoints should be isolated under `/api/mobile/v1/` to ensure full versioning, zero regression on existing web routes, and clean JSON schemas matching Flutter data models.
