# ATLAS System Architecture

## Overview
**ATLAS (Academic Thesis Lifecycle & Assessment Suite)** is a centralized web platform designed for universities to manage the end-to-end lifecycle of undergraduate and postgraduate capstone projects, dissertations, and theses.

The architecture emphasizes:
1. **Clean Layered Separation**: Route handlers -> Service layer business logic -> SQLAlchemy 2.0 ORM models.
2. **Strict Backend Authorization**: Role-Based Access Control (RBAC) enforced in services and route dependencies, not merely hidden in client-side HTML.
3. **Authoritative Server-Side Validation**: Deadlines, proposal state transitions, rubric calculations, and scheduling conflict checks are calculated and guaranteed by the server.

---

## Architectural Diagram

```
+-----------------------------------------------------------------------------------+
|                                  CLIENT LAYER                                     |
|  TailwindCSS + Jinja2 Templates + Dynamic JS Modals / Status Indicators / Charts  |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          | HTTP (HTML / REST API / Form Submissions)
                                          v
+-----------------------------------------------------------------------------------+
|                                  FASTAPI APP                                      |
|  - CORS & Security Headers                                                        |
|  - Auth Middleware (JWT Cookie / Bearer Token resolution -> request.state.user)   |
|  - Flash Messages & Context Processor Dependencies                                |
+-----------------------------------------+-----------------------------------------+
                                          |
        +---------------------------------+---------------------------------+
        |                                                                   |
        v                                                                   v
+-----------------------+                                         +-----------------------+
|   DASHBOARD ROUTERS   |                                         |     API ROUTERS       |
|  - /dashboard/overview|                                         |  - /api/v1/auth       |
|  - /dashboard/teams   |                                         |  - /api/v1/users      |
|  - /dashboard/proposals                                         |  - /api/v1/milestones |
|  - /dashboard/defenses|                                         |  - /api/v1/submissions|
|  - /dashboard/rubrics |                                         |  - /api/v1/evaluations|
+-----------+-----------+                                         +-----------+-----------+
            |                                                                 |
            +---------------------------------+-------------------------------+
                                              |
                                              v
+-----------------------------------------------------------------------------------+
|                                 SERVICE LAYER                                     |
|  - AuthService         - TeamService           - ProposalService                  |
|  - MilestoneService   - SubmissionService     - DefenseService                   |
|  - EvaluationService  - ReportService         - AuditService & Notifications     |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                              PERSISTENCE & STORAGE                                |
|  - SQLAlchemy 2.0 Declarative ORM Models (PostgreSQL / SQLite)                    |
|  - Alembic Database Migrations                                                    |
|  - Secure File Storage System (UUID-safe paths & mime-type validation)            |
+-----------------------------------------------------------------------------------+
```

---

## Core Principles

### 1. Service Layer Design
All business decisions, permission checks, state changes, and calculation logic reside in `api/v1/services/`.
- Controllers (routers) only validate form inputs, invoke service methods, and handle presentation responses (redirects with flash messages or JSON).
- No direct database writes or critical business decisions are executed inside Jinja2 template contexts.

### 2. State Machine Enforcement
Transitions between workflow states (e.g. `DRAFT -> SUBMITTED -> CHANGES_REQUESTED -> APPROVED`) are validated strictly against the `ProposalStatus` and `TeamStatus` state machines. Invalid transitions raise `HTTPException(400)`.

### 3. Server-Side Deadline Validation
Deliverable submissions automatically compare current UTC time with the milestone deadline:
```python
is_late = now > milestone.due_date
status = SubmissionStatus.LATE.value if is_late else SubmissionStatus.SUBMITTED.value
```
Clients cannot override or spoof the submission timestamp.

### 4. Defense Conflict Engine
The `DefenseService` prevents:
- **Room Collisions**: Multiple defenses occupying the same room during overlapping time intervals.
- **Team Collisions**: A single team assigned to multiple concurrent slots.
- **Panel Member Collisions**: Supervisors assigned to evaluate in two different rooms at overlapping times.

---

## Directory Organization
```text
Atlas/
├── api/
│   ├── core/
│   │   └── dependencies/    # Middleware, flash messages, template context
│   ├── db/                  # Database engine, session maker, declarative base
│   ├── utils/               # JWT token utilities, loggers, settings
│   └── v1/
│       ├── models/          # 25 SQLAlchemy models
│       ├── schemas/         # Pydantic schemas for data validation
│       ├── services/        # Service-layer business logic
│       └── routes/
│           ├── dashboard/   # Jinja2 dashboard sub-routers (102 endpoints)
│           └── ...          # REST endpoints
├── frontend/
│   ├── app/
│   │   ├── components/      # Reusable sidebar, header, navbar, modals
│   │   └── pages/dashboard/ # Role-tailored dashboards, teams, proposals, rubrics
│   └── static/              # CSS, Tailwind compiled styles, logos, JS assets
├── scripts/
│   └── seeders/             # Comprehensive 12-stage seed script (seed_atlas.py)
├── tests/                   # 16 unit & integration tests covering the full lifecycle
├── filestorage/             # Uploaded PDF and document artifacts
└── docs/                    # Technical specifications and guides
```
