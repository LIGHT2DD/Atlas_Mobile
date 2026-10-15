# ATLAS — Academic Thesis Lifecycle & Assessment Suite
## Comprehensive System Specification, Architecture & Operations Manual

---

## 1. Executive Summary & System Mental Model

**ATLAS** is an institutional academic management system that governs the complete lifecycle of university capstone projects, undergraduate dissertations, and postgraduate research theses.

In traditional universities, capstone and thesis management is plagued by fragmented communication:
* Unversioned proposal drafts and feedback lost in scattered email threads.
* Students missing critical deadlines due to inconsistent deadline communication.
* Department coordinators spending days cross-referencing paper calendars and room allocations to schedule oral defense hearings without double-booking faculty.
* Grading criteria calculated manually on spreadsheets, leading to calculation discrepancies.

**ATLAS resolves these challenges through a centralized, single source of truth** governed by authoritative server-side state machines, automated conflict detection, and mathematical rubric scoring engines.

---

## 2. System Architecture: The Hybrid Architecture Model

ATLAS is engineered as a **Modern Hybrid Cloud Architecture** combining a high-performance **FastAPI (Python) Relational Core** with **Google Firebase Cloud Services** and a cross-platform **Flutter (Riverpod/Dio)** mobile client.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ATLAS CLIENT APPLICATIONS                             │
│                                                                             │
│   ┌───────────────────────────────┐     ┌───────────────────────────────┐   │
│   │   Flutter Mobile App (iOS/And)│     │   Web Dashboard (Jinja2 / JS) │   │
│   │   - Dio HTTP Client + JWT     │     │   - TailwindCSS + UI Admin    │   │
│   │   - Riverpod State Management │     │   - Live Log Streamer         │   │
│   │   - Secure Token Storage      │     │   - Dynamic Role Navigation   │   │
│   └───────────────┬───────────────┘     └───────────────┬───────────────┘   │
└───────────────────┼─────────────────────────────────────┼───────────────────┘
                    │ REST API                            │ HTTP Session / CSRF
                    ▼                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ATLAS CORE BACKEND ENGINE (FastAPI)                      │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  API Gateway & Middleware Layer                                     │   │
│   │  - JWT Bearer Authentication & Refresh Token Rotation               │   │
│   │  - Strict Role-Based Access Control (RBAC: Coordinator/Super/Stud)  │   │
│   │  - Dynamic Cloud CORS & Health Monitoring (/health, /api/health)    │   │
│   └──────────────────────────────────┬──────────────────────────────────┘   │
│                                      │                                      │
│   ┌──────────────────────────────────┴──────────────────────────────────┐   │
│   │  Authoritative Business Engines                                     │   │
│   │  - Oral Defense Conflict Engine (Zero Room & Jury Overlaps)         │   │
│   │  - Immutable Proposal Versioning & Review State Machine             │   │
│   │  - Weighted Multi-Criteria Rubric Scoring & Letter Grade Calculator │   │
│   │  - Server-Side Late Submission Penalty Engine                       │   │
│   │  - Audit Log & System Activity Ledger                               │   │
│   └──────────────────────────────────┬──────────────────────────────────┘   │
└──────────────────────────────────────┼──────────────────────────────────────┘
                                       │
            ┌──────────────────────────┴──────────────────────────┐
            ▼                                                     ▼
┌───────────────────────────────────────┐   ┌─────────────────────────────────┐
│     RELATIONAL DATA STORE             │   │   FIREBASE COMPANION SERVICES   │
│   (PostgreSQL 15+ / SQLite 3)         │   │   (Cloud Infrastructure)        │
│                                       │   │                                 │
│  - SQLAlchemy 2.0 ORM + Alembic       │   │  - Firebase Cloud Messaging     │
│  - 20+ Relational Entities            │   │    (FCM Instant Push Alerts)    │
│  - Foreign Key Constraints & Cascades │   │  - Firebase Cloud Storage       │
│  - ACID Transactional Integrity       │   │    (Secure Document Archiving)  │
└───────────────────────────────────────┘   └─────────────────────────────────┘
```

---

## 3. Why We Made It a Hybrid Project (Technical Rationale)

A frequent question is: *Why not build the entire backend exclusively on Firebase (Firestore + Cloud Functions), or exclusively as a traditional monolithic server?*

The decision to adopt a **Hybrid Model (FastAPI Core + Firebase Companion Services)** was driven by foundational software engineering and database principles:

### A. Why Pure Firebase (Firestore NoSQL) Fails for Academic Systems
1. **Relational Data Complexity**:
   - ATLAS governs over 20 deeply interconnected entities: `Users`, `Roles`, `Semesters`, `Departments`, `Teams`, `TeamMembers`, `Proposals`, `SupervisorRequests`, `Milestones`, `Submissions`, `Defenses`, `DefensePanelMembers`, `Evaluations`, and `Rubrics`.
   - In Firestore (NoSQL document store), data is denormalized. Enforcing foreign key constraints, cascading updates (e.g., when a student switches teams or a supervisor quota changes), and querying across multi-table relationships requires complex, brittle client-side logic or expensive multi-step Cloud Functions.
2. **ACID Transactions & Academic Integrity**:
   - Final grades, supervisor capacity quotas, and oral defense scheduling cannot tolerate eventual consistency or race conditions.
   - Relational database management systems (RDBMS) guarantee strict ACID compliance and row-level locking, preventing two students from claiming the last supervisor slot simultaneously or two coordinators from booking Room 402 at 10:00 AM.
3. **Complex Mathematical Engines**:
   - The ATLAS evaluation engine computes weighted averages across multiple jury panelists, normalizes scores against criteria weights, and assigns official institutional letter grades (`A+`, `A`, `B-`, `F`). Python's numerical and backend ecosystem handles this authoritatively on the server.
4. **Vendor Lock-In & Institutional Privacy**:
   - Universities often require student academic records to reside on sovereign on-premise infrastructure or standard relational databases (PostgreSQL) rather than proprietary cloud document stores.

### B. Why Pure Monolith (Without Cloud Services) Has Limits
1. **Mobile Push Notifications Require a Native Gateway**:
   - Neither standard HTTP servers nor WebSockets can wake up a sleeping Android or iOS mobile device when an approval arrives or a deadline is published.
   - **Firebase Cloud Messaging (FCM)** is the industry standard for delivering background push alerts directly to mobile devices.
2. **Large Binary Document Storage**:
   - Storing gigabytes of thesis manuscripts, software architectural diagrams, and ZIP archives directly on the web application server degrades I/O performance and complicates horizontal autoscaling.
   - Offloading binary payloads to **Firebase Cloud Storage** provides high-throughput CDN-backed file delivery while keeping the core server lightweight.

### C. The Hybrid Synergy: Best of Both Worlds
| Capability | FastAPI + SQLAlchemy Core | Firebase Companion Layer |
|---|---|---|
| **Identity & Access Control** | Authoritative JWT issuing, RBAC verification | FCM device token registration |
| **Relational Data Integrity** | Foreign keys, cascading deletes, transactions | — |
| **Academic Rubrics & Math** | Weighted rubric calculations, conflict engine | — |
| **Push Notifications** | Event dispatch triggers | Real-time push delivery to iOS/Android |
| **Document Management** | Metadata, access authorization, audit logs | Distributed blob storage & CDN delivery |
| **Hosting & Portability** | Runs on Docker, Render, Railway, Cloud Run | Global Google infrastructure |

---

## 4. Complete Feature Matrix & Capabilities

### 🏛️ 1. Coordinator (Academic Administrator) Features
* **Semester & Term Orchestration**:
  - Activate, transition, or close academic semesters.
  - Configure global parameters: maximum team size, supervisor student quota, proposal deadlines.
* **Faculty & Quota Management**:
  - Monitor supervisor workload allocations and enforce faculty project limits.
  - Override supervisor assignments when student teams require matching.
* **Oral Defense Scheduling & Conflict Engine**:
  - Schedule oral defense hearings across physical venues/rooms.
  - Select multi-faculty jury panels.
  - **Automated Conflict Detection**: The server actively rejects bookings if any jury panelist or venue is double-booked during the selected time interval.
* **Grade Registry & Publication**:
  - Review panel evaluation summaries.
  - Authoritatively publish final grades to student transcripts with one click.
* **Institutional Audit Trail**:
  - View real-time system logs and action histories tracking all approvals, uploads, and edits.

### 👨‍🏫 2. Supervisor (Faculty Mentor & Examiner) Features
* **Supervision Request Management**:
  - Review incoming supervision requests from student teams with pitch summaries.
  - Accept or decline requests with capacity validation.
* **Proposal Review & Iteration**:
  - Review proposal drafts with iteration notes.
  - Request modifications with structured feedback or grant formal supervisor approval.
* **Milestone & Deliverable Evaluation**:
  - Track student team progress across milestones (e.g., SRS, Architecture, Final Report).
  - Inspect submitted documents with server-verified timestamps.
  - Submit structured milestone feedback and grades.
* **Oral Defense Jury Scoring**:
  - Access assigned defense panels.
  - Score candidates using multi-criteria rubrics with automated weighted calculations.

### 🎓 3. Student (Thesis Candidate) Features
* **Team Formation & Invitation Hub**:
  - Create a new project team for the active semester.
  - Generate and share a unique 10-character team invite code.
  - Teammates join seamlessly by entering the invite code.
* **Faculty Supervisor Discovery**:
  - Explore faculty directories, research interests, and open capacity slots.
  - Submit structured supervision requests directly to chosen faculty.
* **Proposal Submission & Iteration**:
  - Submit initial proposal title, research problem, methodology, and expected outcomes.
  - Upload proposal revisions in response to supervisor review notes.
* **Milestone Deliverable Submissions**:
  - View upcoming deadlines with countdown timers.
  - Upload PDF reports, presentation slides, or source code archives.
  - Immediate visibility into server-side late submission status.
* **Defense & Grade Center**:
  - View assigned oral defense date, time, venue, and designated committee members.
  - View published final evaluation rubrics, scores, and official letter grades.

### ⚙️ 4. Cross-Cutting Core Technical Engines
* **Immutable Proposal Versioning**:
  - Proposal edits create version snapshots, preventing disputes regarding what was submitted.
* **Authoritative Server-Side Late Detection**:
  - Deadlines are evaluated against UTC server timestamps; client device clock tampering has zero effect on submission status.
* **Unified Auth & Dynamic Role Routing**:
  - Single login entrypoint dynamically routes users to their role-specific dashboard views.
* **Secure Token Lifecycle**:
  - Mobile client features automatic token refresh via Dio interceptors with zero user interruption.

---

## 5. How to Run the Application (Complete Runbook)

### 🚀 Mode A: Cloud Deployment (Permanent 24/7 Server — Zero Local Server Needed)
In this mode, the backend runs continuously in the cloud. The Flutter mobile app connects directly over the internet without needing to run `uvicorn` or any terminal command on your computer.

#### 1. Deploy the Backend to Render (1-Click Blueprint)
The repository includes [render.yaml](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/render.yaml) and a dynamic [Dockerfile](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/Dockerfile):
1. Push your repository to GitHub or GitLab.
2. Sign in to [Render.com](https://render.com).
3. Click **New +** > **Blueprint** and select your repository.
4. Render automatically reads `render.yaml`, provisions the container, and assigns a live public URL (e.g. `https://atlas-api.onrender.com`).
5. Verify health: visit `https://atlas-api.onrender.com/health` in your browser.

#### 2. Deploy the Backend to Google Cloud Run (Alternative)
Because Cloud Run integrates natively with Firebase/GCP:
```bash
# Build and deploy container directly to Cloud Run
gcloud run deploy atlas-api \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

#### 3. Run the Mobile App Pointing to the Cloud Backend
Run the Flutter app pointing to your live cloud URL:
```bash
cd mobile

# Run on physical phone, emulator, or web against your cloud backend:
flutter run --dart-define=API_BASE_URL=https://atlas-api.onrender.com

# Build a release Android APK:
flutter build apk --release --dart-define=API_BASE_URL=https://atlas-api.onrender.com
```

---

### 💻 Mode B: Local Development Execution

If developing offline or making local modifications to backend Python code:

#### Prerequisites
* Python 3.10+ (preconfigured `.venv` included in workspace)
* Flutter 3.12+ / Dart 3.x
* Android Emulator, Chrome, or physical device

#### Step 1: Start the Local FastAPI Backend
From the root workspace directory (`Atlas`):
```powershell
# Windows PowerShell:
.venv\Scripts\python -m uvicorn main:app --reload --port 8000

# macOS / Linux:
source .venv/bin/activate
uvicorn main:app --reload --port 8000
```
Verify the server is running: open [http://localhost:8000/health](http://localhost:8000/health).

#### Step 2: Start the Flutter Mobile Application
Open a second terminal:
```powershell
cd mobile

# Option 1: Run on Android Emulator (auto-routes to 10.0.2.2:8000)
flutter run

# Option 2: Run in Chrome browser
flutter run -d chrome

# Option 3: Run on Physical Phone (connected to the same Wi-Fi)
# Replace 192.168.1.X with your PC's local network IP:
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
```

#### Step 3: One-Click Startup in VS Code (No Separate Terminals Needed)
Preconfigured VS Code configurations are provided in `.vscode/`:
1. Open the project in **VS Code**.
2. Press `Ctrl + Shift + D` (or open the **Run & Debug** tab).
3. Select **"Atlas Mobile (Local Server Auto-Start)"** and press **F5**.
4. VS Code runs the `.vscode/tasks.json` task to automatically launch `uvicorn` in the background and then boots the Flutter mobile app.

#### Step 4: Run via Docker Compose (Optional)
To run PostgreSQL and the web backend in isolated containers:
```bash
docker compose up -d
```
The backend will run continuously in the background and survive system reboots.

---

## 6. Pre-Configured Test Accounts & Credentials

The database contains pre-seeded accounts representing all stages of the academic lifecycle:

| Role | Email | Password | Pre-loaded State in Database |
|:---|:---|:---|:---|
| **🏛️ Coordinator** | `coordinator@atlas.edu` | `Password123` | Full administrative control; manages active semester, defenses, rubrics, and grade registry. |
| **👨‍🏫 Supervisor** | `supervisor1@atlas.edu` | `Password123` | Assigned supervisor of Team Apollo; reviews pending submissions and defense scoring. |
| **🎓 Student (Leader)** | `student1@atlas.edu` | `Password123` | Leader of Team Apollo (Proposal Approved, Final Grade: A+ published). |
| **🎓 Student (Milestones)**| `student4@atlas.edu` | `Password123` | Leader of Team Cipher (Active milestone submissions, SRS graded). |

---

## 7. Database Migrations & Seeders

### Database Architecture
* By default, the application runs on SQLite (`atlas.db`) in the root directory for zero-friction setup.
* In production or Docker environments, it points to PostgreSQL via the `DB_URL` environment variable.

### Running Migrations (Alembic)
```powershell
# Upgrade database schema to latest version
.venv\Scripts\python -m alembic upgrade head

# Create a new migration revision after model changes
.venv\Scripts\python -m alembic revision --autogenerate -m "describe_changes"
```

### Running Test Suite
```powershell
# Run the complete mobile API test suite
.venv\Scripts\python -m pytest tests/test_mobile_api.py -v
```

---

## 8. Summary Checklist: What Was Changed for Option A

1. **[api_config.dart](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/mobile/lib/core/config/api_config.dart)**:
   - Added compile-time `--dart-define=API_BASE_URL=...` support.
   - Added `defaultProductionUrl` constant for cloud fallbacks in release builds.
   - Added runtime dynamic override via `setCustomBaseUrl()`.
2. **[Dockerfile](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/Dockerfile)**:
   - Made the port dynamic via `${PORT:-8000}` to ensure compatibility with Cloud Run, Render, Railway, and Heroku.
3. **[main.py](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/main.py)**:
   - Added `/health` and `/api/health` endpoints for cloud provider health checks.
   - Enhanced CORS regex (`allow_origin_regex=r"^https?://.*$"`) to support cross-origin cloud clients and Flutter Web.
4. **[render.yaml](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/render.yaml) & [Procfile](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/Procfile)**:
   - Added 1-click cloud blueprint configurations for Render and containerized PaaS platforms.
5. **[.vscode/tasks.json](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/.vscode/tasks.json) & [.vscode/launch.json](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/.vscode/launch.json)**:
   - Added one-click auto-server launch configs for local development in VS Code.
