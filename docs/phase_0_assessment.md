# ATLAS — Academic Thesis Lifecycle & Assessment Suite
## Phase 0: Architectural Inspection & Implementation Assessment

---

### 1. Executive Summary

This assessment details the inspection of the existing **ProjectHub / Final Year Project Management System** codebase and defines the transition strategy to deliver **ATLAS (Academic Thesis Lifecycle & Assessment Suite)**.

The project is built on **Python 3.12+ / FastAPI**, **SQLAlchemy 2.0 ORM**, **Jinja2 Server-Side Rendering**, **Tailwind CSS v4 (CDN)**, and **PyJWT / BCrypt** authentication. The core web architecture is sound, responsive, and functional. Rather than performing a risky complete framework rewrite (e.g. Next.js), we will preserve and expand this proven architecture, transforming its domain models, workflows, branding, and role-based workspaces into the complete ATLAS academic lifecycle.

---

### 2. Current Architecture Inventory

| Component | Current Implementation | ATLAS Direction |
|---|---|---|
| **Backend Framework** | FastAPI 0.115 + Uvicorn | Retain, expand API routes with strict REST conventions and Pydantic schemas. |
| **ORM & Database** | SQLAlchemy 2.0 with `BaseTableModel` CRUD abstraction; SQLite (dev) / PostgreSQL (prod) | Retain `BaseTableModel`; add `Semester`, `Team`, `TeamMember`, `SupervisorRequest`, `Proposal`, `ProposalVersion`, `ProposalReview`, `Rubric`, `Evaluation`, `DefenseSchedule`, `AuditLog`. |
| **Database Migrations** | Alembic installed; `Base.metadata.create_all()` used | Standardize models and provide working migration script + seed script. |
| **Authentication** | PyJWT + BCrypt; HTTP-only cookies (`access_token`, `refresh_token`); `AuthMiddleware` | Retain & harden. Enforce 3 roles: `STUDENT`, `SUPERVISOR`, `COORDINATOR`. |
| **Role-Based Access Control (RBAC)** | Roles: `admin`, `student`, `supervisor`. Role check in some views. | Formalize `COORDINATOR`, `SUPERVISOR`, `STUDENT`. Enforce strict backend permission checks on every route. |
| **Frontend Architecture** | Jinja2 templates (`frontend/app`), partial components, Tailwind CSS v4 CDN, FontAwesome 7, vanilla JS | Modernize into an authoritative academic suite UI; role-specific sidebars, status badges, timelines, modals, error/empty states. |
| **File Storage** | Local storage under `filestorage/` with extension & size validation (optional Firebase sync) | Retain and harden; secure document download authorization per team/role. |
| **Testing** | No tests currently in repository | Add comprehensive `pytest` test suite covering Auth, RBAC, Teams, Proposals, Milestones, Defenses, and Rubrics. |

---

### 3. Reusable Components vs. Modifications

#### Reusable Components
1. **BaseTableModel** (`api/core/base/base_model.py`): Robust UUID generation, soft deletion, timestamps, pagination (`all()`), `fetch_by_id`, `update`, `to_dict`.
2. **Auth & Token Services** (`api/v1/services/auth.py`, `token.py`): Password hashing, JWT access/refresh token generation and verification, reset-password tokens.
3. **Paginator & Loggers** (`api/utils/paginator.py`, `loggers.py`): Standardized page and size parsing.
4. **Local File Storage Engine** (`api/v1/services/document.py`): Secure file storage with filename sanitization and extension whitelisting.
5. **Flash Messages & Sessions** (`api/core/dependencies/flash_messages.py`): User notification flash messages across redirects.

#### Features to Remove / Redesign
1. **ProjectHub Branding**: Replace all instances of `ProjectHub`, `FYPMS`, and `@projecthub.com` with `ATLAS` and `@atlas.edu`.
2. **Loose "Projects" Model**: Redesign into academic **Teams** linked to a **Semester** with enforced team size limits, team leader assignment, and member constraints.
3. **Direct Supervisor Attachment**: Replace with a formal **Supervisor Request & Assignment** workflow.
4. **Informal Submission Status**: Replace with ATLAS **Proposal State Machine** (`DRAFT` → `SUBMITTED` → `CHANGES_REQUESTED` → `SUBMITTED` → `APPROVED`/`REJECTED`) with immutable **Proposal Versioning**.
5. **Admin Terminology**: Rename and elevate the `ADMIN` role to **`COORDINATOR`** with dedicated oversight views for Semesters, Defenses, Rubrics, Audit Logs, and Grade Publications.

#### Missing ATLAS Features to Implement
1. **Semester Entity**: Multi-session academic year management (`Semester`).
2. **Proposal Lifecycle & Versioning**: `Proposal`, `ProposalVersion`, and `ProposalReview` entities.
3. **Coordinator-Configured Milestones & Deadlines**: Semester-wide milestones with automated backend late submission calculations.
4. **Evaluation & Rubric System**: Configurable criteria with percentage weights, panel scoring, and final weighted grade calculations.
5. **Defense Scheduling with Conflict Detection**: Scheduling algorithm preventing overlapping defenses for teams, supervisors/panel members, and rooms.
6. **Audit Logging**: Comprehensive activity tracking for compliance and coordinators.
7. **Reporting & Data Export**: CSV export endpoints for all academic datasets.

---

### 4. Database Schema Strategy

The database will be extended with the following interconnected models:

```
Semester (1) ───< (N) Team (1) ───< (N) TeamMember (N) >─── User (1)
   │                    │
   │                    ├───< (N) SupervisorRequest
   │                    │
   │                    ├───< (1) Proposal ───< (N) ProposalVersion ───< (N) ProposalReview
   │                    │
   │                    ├───< (N) Submission (1) >─── (N) Milestone
   │                    │
   │                    ├───< (1) DefenseSchedule ───< (N) DefensePanelMember
   │                    │
   │                    └───< (N) Evaluation ───< (N) EvaluationScore (N) >─── EvaluationCriteria
   │
   └───< (N) Milestone
```

All models inherit from `BaseTableModel` ensuring UUID primary keys, soft deletion, audit timestamps, and serialization.

---

### 5. Implementation Roadmap (Phases 1–12)

- **Phase 1: Branding & Visual Foundation**: Clean ProjectHub references; update logos, headers, footers, page titles, and color palette.
- **Phase 2: Authentication & Strict RBAC**: Ensure `COORDINATOR`, `SUPERVISOR`, and `STUDENT` roles have strict backend route guards.
- **Phase 3: Semester & Team & Supervisor Request Management**: Implement `Semester`, `Team`, `TeamMember`, and `SupervisorRequest` models and workflows.
- **Phase 4: Proposal State Machine & Immutable Versioning**: Build `Proposal`, `ProposalVersion`, `ProposalReview` with state transitions.
- **Phase 5: Semester Milestones, Submissions & Document Management**: Configure milestones, automatic late detection, and submission attachments.
- **Phase 6: Evaluation Rubrics & Final Grade Calculation**: Implement criteria weighting, score entry, and backend grade calculation.
- **Phase 7: Defense Scheduling with Conflict Detection**: Interactive scheduling with conflict detection for rooms, teams, and panel members.
- **Phase 8: Notifications & Audit Logging**: Automatic notification dispatch and persistent audit logging.
- **Phase 9: Role-Specific Dashboards**: Custom dashboards for Student, Supervisor, and Coordinator with key metrics.
- **Phase 10: Reports & Data Export**: CSV export endpoints for all academic datasets.
- **Phase 11: Automated Test Suite & Security Review**: Full `pytest` coverage for Auth, RBAC, Teams, Proposals, Submissions, Defenses, and Rubrics.
- **Phase 12: Seed Data, Documentation & Verification**: Comprehensive realistic seed script, complete README, and end-to-end lifecycle verification.
