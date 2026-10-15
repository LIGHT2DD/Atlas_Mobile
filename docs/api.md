# ATLAS API Reference

ATLAS exposes both **RESTful JSON endpoints** (under `/api/v1/*`) and **Dashboard Form/Action controllers** (under `/dashboard/*`). All endpoints require appropriate authentication and role authorization.

---

## 1. Authentication & Session

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/api/v1/auth/login` | POST | Public | Authenticate with email/password; returns JWT access and refresh tokens. |
| `/api/v1/auth/logout` | POST | Authenticated | Revoke session and clear authentication cookies. |
| `/api/v1/auth/refresh` | POST | Authenticated | Issue new access token from valid refresh token. |
| `/auth/student` | POST | Public | Student login with session cookies. |
| `/auth/supervisor` | POST | Public | Faculty supervisor login with session cookies. |
| `/auth/admin` | POST | Public | Coordinator login with session cookies. |

---

## 2. Semester Management (Coordinator)

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/dashboard/semesters` | GET | Coordinator | List all academic semesters. |
| `/dashboard/semesters/new` | POST | Coordinator | Create new semester term with team limits. |
| `/dashboard/semesters/{id}/activate` | POST | Coordinator | Set active academic term. |

---

## 3. Team Formation & Supervisor Assignment

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/dashboard/teams` | GET | All Roles | View teams (Student: personal team; Faculty/Admin: roster). |
| `/dashboard/teams/new` | POST | Student | Form new team; creator automatically designated as leader. |
| `/dashboard/teams/join` | POST | Student | Join an existing team using its unique 6-character invite code. |
| `/dashboard/teams/{id}/leave` | POST | Student | Leave team (only permitted while in FORMING state). |
| `/dashboard/teams/{id}/request-supervisor` | POST | Student | Team leader requests faculty supervision. |
| `/dashboard/teams/{id}/assign-supervisor` | POST | Coordinator | Administratively assign or reassign supervisor. |
| `/dashboard/requests` | GET | Supervisor | Supervisor inbox for pending supervision requests. |
| `/dashboard/requests/{id}/respond` | POST | Supervisor | Accept or decline team supervision request. |

---

## 4. Proposal Lifecycle & Versioning

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/dashboard/proposals` | GET | All Roles | Proposal list filtered by role permissions. |
| `/dashboard/proposals/detail/{id}` | GET | All Roles | Detailed view with version history and reviews. |
| `/dashboard/proposals/submit` | POST | Student | Submit initial proposal or revised version. |
| `/dashboard/proposals/{id}/review` | POST | Supervisor | Review proposal (`approved`, `changes_requested`, `rejected`). |

---

## 5. Deliverables & Submissions

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/dashboard/milestones` | GET | All Roles | View milestone cards, weights, and deadlines. |
| `/dashboard/milestones/new` | POST | Coordinator | Create milestone deliverable. |
| `/dashboard/deadlines` | GET | All Roles | Chronological timeline of upcoming and overdue milestones. |
| `/dashboard/submissions` | GET | All Roles | Submission list and grading status. |
| `/dashboard/submissions/new` | POST | Student | Submit deliverable against milestone (checks deadline server-side). |
| `/dashboard/submissions/{id}/grade` | POST | Supervisor | Grade deliverable with score and feedback comments. |

---

## 6. Oral Defense & Conflict Detection

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/dashboard/defense` | GET | All Roles | Timetable of scheduled oral defenses. |
| `/dashboard/defense/schedule` | POST | Coordinator | Schedule defense slot with automated room/panel conflict checks. |

---

## 7. Rubrics, Evaluation & Grades

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/dashboard/rubrics` | GET | Coordinator | View and configure criteria weights. |
| `/dashboard/rubrics/new` | POST | Coordinator | Create rubric criterion (max score, percentage weight). |
| `/dashboard/evaluations` | GET | Faculty/Admin | Defense scoring roster. |
| `/dashboard/evaluations/{team_id}/submit` | POST | Supervisor | Submit scores across rubric items. |
| `/dashboard/grades` | GET | All Roles | Grade center (Student: published grade; Admin: publishing portal). |
| `/dashboard/grades/{team_id}/publish` | POST | Coordinator | Authoritatively publish final grade and score. |

---

## 8. Reports & Audit Logs

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/dashboard/reports` | GET | Coordinator | Report generation hub. |
| `/dashboard/reports/{type}/export` | GET | Coordinator | Export CSV report (`grades`, `proposals`, `teams`, `submissions`, `defenses`, `users`). |
| `/dashboard/audit-logs` | GET | Coordinator | Searchable security and lifecycle event log. |
| `/dashboard/notifications` | GET | All Roles | Notification center. |
| `/dashboard/notifications/read-all` | POST | All Roles | Mark all notifications as read. |
