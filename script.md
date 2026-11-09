# ATLAS — Project Proposal Presentation Script
## Spoken Word-for-Word Delivery Guide & Committee Defense Script

---

**Presenter:** Md Al Sabber Rahman  
**Course Teacher:** Tanvir Ahmed  
**Course Title & Code:** Software Engineering Capstone Project / CSE 4200  
**Target Duration:** 8 to 10 Minutes Total  
**Follow-up Q&A Session:** 3 to 5 Minutes  
**Accompanying Slide Document:** [`project_proposal.md`](file:///e:/Virtual%20Stdio%20Codes/Mobile%20Application/projects/Atlas/project_proposal.md)  

---

## Presentation Timing & Pacing Blueprint

| Slide # | Slide Title | Target Time | Cumulative Time | Key Speaking Objective |
|:---:|---|:---:|:---:|---|
| **Slide 1** | Title & Academic Identifiers | 0:30 min | 0:30 min | Welcome, professional introduction, and project thesis statement. |
| **Slide 2** | Introduction & Problem Statement | 1:00 min | 1:30 min | Articulate the operational chaos of manual thesis management. |
| **Slide 3** | Project Objectives | 0:45 min | 2:15 min | Define 1 general and 6 achievable specific engineering goals. |
| **Slide 4** | Existing System vs. Proposed Solution | 1:00 min | 3:15 min | Compare current ad-hoc methods vs. ATLAS; address LMS alternatives. |
| **Slide 5** | Project Scope & Target Users | 0:45 min | 4:00 min | Detail the 3 roles; strictly bound Scope In vs. Scope Out. |
| **Slide 6** | Functional & Non-Functional Requirements | 1:00 min | 5:00 min | Highlight 6 core functional modules and key quality attributes. |
| **Slide 7** | System Analysis & Design Diagrams | 1:15 min | 6:15 min | Walk through Use Cases, Multi-Tier Architecture, and Relational ER. |
| **Slide 8** | Proposed Features & System Workflow | 1:00 min | 7:15 min | Walk through the 12-stage sequential workflow and Neumorphic UI. |
| **Slide 9** | Technology Stack & Technical Rationale | 0:45 min | 8:00 min | Justify FastAPI, Flutter, SQLite WAL, and Riverpod. |
| **Slide 10** | Development Methodology & Testing Plan | 0:45 min | 8:45 min | Explain Agile sprints and the multi-level automated test plan. |
| **Slide 11** | Project Timeline & Team Responsibilities | 0:45 min | 9:30 min | Present the 14-week Gantt schedule and module ownership. |
| **Slide 12** | Expected Outcomes, Risks & Conclusion | 0:45 min | 10:15 min | Summarize deliverables, risk mitigations, and invite Q&A. |

---

## Word-for-Word Presentation Script

### [SLIDE 1: TITLE SLIDE]
*(Elapsed Time: 0:00 – 0:30)*

> "Respected Course Teacher Tanvir Ahmed sir, honorable committee members, and dear peers—good morning.
>
> I am **Md Al Sabber Rahman**, and today I am privileged to present our software engineering project proposal titled: **ATLAS — Academic Thesis Lifecycle & Assessment Suite**.
>
> In university environments, managing undergraduate capstone projects and postgraduate dissertations is one of the most critical yet operationally challenging processes in the academic calendar. ATLAS is engineered to be a centralized, multi-role academic research governance platform that replaces fragmented emails and spreadsheets with authoritative lifecycle automation, mathematical conflict detection, and weighted rubric evaluation.
>
> Over the next nine minutes, I will walk you through our problem definition, architectural design, engineering methodology, and verifiable implementation plan."

---

### [NEXT SLIDE: SLIDE 2 — INTRODUCTION & PROBLEM STATEMENT]
*(Elapsed Time: 0:30 – 1:30)*

> "Let us examine the problem domain.
>
> Final-year thesis management involves three core stakeholders: students conducting research, faculty mentors supervising their progress, and department coordinators handling logistics and accreditation.
>
> In our universities today, this entire lifecycle is handled through ad-hoc mechanisms: scattered email threads, messaging apps, and manual Excel spreadsheets.
>
> This creates four severe bottlenecks:
> 1. **First, proposal versions get lost.** Students submit drafts via email, supervisors reply with revisions, and soon nobody knows whether feedback was applied to version one, version two, or an outdated draft.
> 2. **Second, oral defense scheduling is an administrative nightmare.** Coordinators manually schedule dozens of defense sessions. Without automated collision checks, seminar rooms get double-booked and professors find themselves assigned to two different defense panels at the exact same hour.
> 3. **Third, milestone deadlines and late penalties are contentious.** Without authoritative server-side timestamps, students and faculty often dispute when work was submitted.
> 4. **Fourth, defense grading is prone to arithmetic error.** Panelists score candidates on paper slips, and manually computing weighted percentages often leads to calculation errors and delays in publishing final transcripts.
>
> Consider Team Apollo: they submit a proposal revision via Google Drive, but the supervisor accidentally marks up the older email attachment. On defense day, their defense in Seminar Hall B is halted because an examiner is concurrently seated in another room.
>
> **The core question is:** What problem are we solving? We are solving the operational chaos, scheduling collisions, and lack of transparency in academic thesis governance—and it demands an authoritative software solution."

---

### [NEXT SLIDE: SLIDE 3 — PROJECT OBJECTIVES]
*(Elapsed Time: 1:30 – 2:15)*

> "To solve these challenges, we have defined one general objective and six specific, achievable engineering goals for this semester.
>
> Our **General Objective** is to design, implement, and verify ATLAS as a complete full-stack system that digitizes the entire thesis lifecycle from team inception to final certified grade publication.
>
> Our **Specific Objectives** are:
> * **1. Team Formation & Supervision Matching:** Allowing students to form cohorts using secure 6-character alphanumeric invite codes and pitch research topics to faculty.
> * **2. Immutable Proposal Versioning:** Creating a dedicated snapshot engine that records versions $v1, v2, \dots vN$ with full change summaries and supervisor critiques.
> * **3. Milestone & Late Detection:** Enforcing server-side UTC deadline validation for PDF deliverables and GitHub repositories.
> * **4. Algorithmic Defense Conflict Prevention:** Formulating a three-way interval overlap algorithm that guarantees zero room, panelist, or student scheduling clashes.
> * **5. Weighted Rubric Math:** Automating composite grade calculations across multiple examiners and mapping them to official letter grades.
> * **6. Cross-Platform Delivery:** Deploying an asynchronous FastAPI backend alongside a native Flutter Android mobile app featuring an iOS-inspired Neumorphic Soft UI.
>
> These objectives directly yield a 90% reduction in administrative overhead and 100% auditable record retention."

---

### [NEXT SLIDE: SLIDE 4 — EXISTING SYSTEM AND PROPOSED SOLUTION]
*(Elapsed Time: 2:15 – 3:15)*

> "Examiners often ask: *'Why not simply use Google Classroom, Canvas, or Jira?'*
>
> If you look at the comparative analysis on this slide, general-purpose LMS platforms are engineered for course homework assignments, not research lifecycles.
>
> * They do not support student-formed cohorts with invite codes.
> * They lack two-sided faculty pitching and formal supervision acceptance.
> * They do not maintain an immutable proposal version history with supervisor revision cycles.
> * Most crucially, they have zero concept of defense room booking, panel assignment, or algorithmic collision detection.
>
> **ATLAS solves this by establishing a single source of truth.**
>
> Our proposed solution replaces paper evaluation slips with digital rubric aggregation, replaces manual calendar checks with server-side collision validation, and provides an authoritative audit log for university accreditation bodies such as BAETE and ABET."

---

### [NEXT SLIDE: SLIDE 5 — PROJECT SCOPE AND TARGET USERS]
*(Elapsed Time: 3:15 – 4:00)*

> "Next, let us establish the system scope and target users.
>
> ATLAS models three strictly isolated academic roles:
> 1. **Students:** Who form teams, pitch ideas, submit iterative drafts, upload code deliverables, and view certified results.
> 2. **Faculty Supervisors:** Who accept or decline supervision pitches, annotate proposal revisions, evaluate milestones, and score oral defenses.
> 3. **Department Coordinators:** Who manage academic semesters, enforce team size limits, appoint defense panels, and publish final transcripts.
>
> To ensure the project is achievable within the semester, we have drawn clear functional boundaries:
> * **Scope IN:** Full authentication, team join codes, proposal versioning, milestone tracking, algorithmic defense scheduling, weighted rubrics, and mobile push notifications.
> * **Scope OUT:** We have explicitly excluded commercial Turnitin plagiarism API subscriptions due to licensing fees, university tuition payment gateways, and live video conferencing streaming. This prevents scope creep while keeping the core thesis governance flawless."

---

### [NEXT SLIDE: SLIDE 6 — FUNCTIONAL AND NON-FUNCTIONAL REQUIREMENTS]
*(Elapsed Time: 4:00 – 5:00)*

> "Slide 6 outlines our requirements baseline.
>
> On the functional side, we specify six primary capabilities:
> * Role-Based Access Control isolating the three personas;
> * Team creation and member enrollment via join codes;
> * Proposal drafting and multi-round version resubmissions;
> * Milestone tracking with automatic server-side UTC late flags;
> * Automated defense scheduling with three-way collision prevention;
> * And multi-criteria weighted rubric grading.
>
> On the non-functional side, we hold the software to rigorous engineering standards:
> * **Security:** Passwords hashed with salted Bcrypt; tokens stored in hardware-backed Android Keystores; and interim defense scores strictly hidden from students until officially released.
> * **Performance:** API response times under 100 milliseconds and 60 FPS mobile rendering.
> * **Reliability & Concurrency:** ACID-compliant relational transactions with SQLite in Write-Ahead Logging mode to ensure writers never block readers.
> * **Usability:** A tactile Neumorphic Soft UI with clear shimmer loading indicators and responsive error toasts."

---

### [NEXT SLIDE: SLIDE 7 — SYSTEM ANALYSIS AND DESIGN]
*(Elapsed Time: 5:00 – 6:15)*

> "Turning to system analysis and design:
>
> * **First, the Use Case Diagram on the left** captures our core actors interacting with the system boundary, with real-time push alerts coordinated through Firebase Cloud Messaging.
> * **Second, in the center, our Multi-Tier Architecture** illustrates our decoupled approach. Mobile clients communicate via HTTPS REST JSON calls to our FastAPI gateway. Requests pass through rate limiters, CORS policies, and authentication middleware before reaching our modular domain services—such as `DefenseService` and `ProposalService`. These services interact with our relational database through SQLAlchemy 2.0.
> * **Third, our Entity-Relationship Model on the right** reflects 21 normalized relational entities. Notice how semesters govern teams, teams draft versioned proposals, milestones require submissions, and defense schedules appoint panel members who submit multi-criteria evaluation scores. Relational foreign keys and cascade rules guarantee data integrity with zero orphan records."

---

### [NEXT SLIDE: SLIDE 8 — PROPOSED FEATURES AND SYSTEM WORKFLOW]
*(Elapsed Time: 6:15 – 7:15)*

> "Slide 8 details our 12-stage sequential workflow.
>
> As shown in the sequence diagram:
> 1. The Coordinator sets up the semester and milestones.
> 2. The Student Leader creates a team, invites peers, and pitches their research to a professor.
> 3. Once accepted, the team drafts proposal version one.
> 4. The supervisor reviews it; if changes are requested, the team submits version two with a change summary.
> 5. Approval unlocks the milestone deliverable phase.
> 6. Students submit PDFs and repository links, where server-side UTC checks flag late submissions.
> 7. The coordinator books the oral defense. At this precise moment, our **Defense Collision Engine** validates that the room is vacant, the team has no other hearing, and none of the committee members are booked concurrently.
> 8. Finally, examiners submit weighted rubric scores, and the coordinator reviews and officially locks the certified grade.
>
> On the mobile frontend, all of this is wrapped in a tactile Neumorphic Soft UI, featuring custom cards, depressible buttons, and dynamic light and dark theme modes."

---

### [NEXT SLIDE: SLIDE 9 — TECHNOLOGY STACK AND TOOLS]
*(Elapsed Time: 7:15 – 8:00)*

> "Let us justify our technology stack.
>
> Every technology was selected for performance, feasibility, and type safety:
> * **FastAPI and Python 3.10+:** Provide asynchronous throughput, native Pydantic schema validation, and automatic OpenAPI documentation.
> * **Flutter and Dart:** Compile directly to native ARM64 machine code, eliminating the performance lag of hybrid WebViews.
> * **Flutter Riverpod 2.6:** Ensures compile-time safe state management. Using fine-grained selectors, only the affected widgets rebuild when state updates, optimizing device CPU and battery.
> * **SQLite in WAL Mode & SQLAlchemy 2.0:** Delivers lightning-fast local persistence with zero operational overhead during development, while remaining completely engine-agnostic and ready for PostgreSQL in production.
> * **Firebase Cloud Messaging:** Delivers real-time push notifications directly to user device status bars.
>
> We prioritized feasibility and elegance over unnecessarily bloated distributed architectures."

---

### [NEXT SLIDE: SLIDE 10 — DEVELOPMENT METHODOLOGY AND TESTING PLAN]
*(Elapsed Time: 8:00 – 8:45)*

> "We adopted an **Agile / Incremental Process Model** organized into four distinct three-week sprints.
>
> This allowed us to complete the core domain models and authentication in Sprint 1, team and proposal lifecycles in Sprint 2, defense conflict algorithms and rubrics in Sprint 3, and mobile client engineering and automated testing in Sprint 4.
>
> Our quality assurance plan is comprehensive and multi-tiered:
> * **Unit Tests:** Pytest verifies backend models, schemas, and rubric math; Dart tests verify Riverpod state controllers.
> * **Integration Tests:** FastAPI `TestClient` verifies API routes, status codes, and database rollback behaviors.
> * **Conflict Tests:** We deliberately inject overlapping room and examiner schedules to prove our conflict engine rejects invalid bookings with HTTP 409.
> * **Token Tests:** We verify that expired tokens trigger transparent background refreshes without crashing the mobile app.
>
> Our test suite currently achieves a **100% pass rate across 72 automated test cases** with zero static analysis warnings."

---

### [NEXT SLIDE: SLIDE 11 — PROJECT TIMELINE AND TEAM RESPONSIBILITIES]
*(Elapsed Time: 8:45 – 9:30)*

> "Slide 11 presents our 14-week project timeline and module ownership.
>
> As shown in the schedule table, our work progressed systematically through requirement analysis, database architecture, team workflows, proposal engines, defense scheduling, and final verification.
>
> As the lead full-stack developer and presenter, my responsibilities encompass:
> * Designing the 21 relational database models and schema relationships;
> * Implementing the FastAPI backend endpoints and modular business services;
> * Formulating the three-way interval defense collision detection algorithm;
> * Building the native Flutter mobile client with Neumorphic styling;
> * And engineering the automated test suite and Docker containerization.
>
> All progress has been tracked through version control on GitHub with structured milestone deliverables."

---

### [NEXT SLIDE: SLIDE 12 — EXPECTED OUTCOMES, RISKS & CONCLUSION]
*(Elapsed Time: 9:30 – 10:15)*

> "In conclusion, let us review our demonstrable deliverables:
> * A fully operational, high-performance FastAPI backend;
> * A standalone, optimized 20.86 MB ARM64 Android release APK;
> * An automated defense conflict engine that mathematically eliminates room and professor double-booking;
> * An immutable proposal snapshot engine and weighted rubric grading registry;
> * And a complete test suite with 100% verification.
>
> We also proactively mitigated key project risks: configuring SQLite WAL mode to avoid database locking, implementing Dio queued interceptors to prevent token expiration crashes, and isolating interim grades to protect academic confidentiality.
>
> ATLAS transforms academic thesis governance from a chaotic, paper-based burden into a modern, transparent, and auditable digital experience.
>
> Thank you, Tanvir Ahmed sir and respected committee members, for your kind attention. I am now ready and eager to answer your questions."

---

## 3 to 5-Minute Committee Q&A Preparation & Defensible Answers

### Question 1: *"Why did you choose SQLite instead of a dedicated PostgreSQL server?"*
* **Defensible Answer:**
  > *"Thank you, sir. We configured SQLite specifically with Write-Ahead Logging (`PRAGMA journal_mode=WAL`) and a 5000-millisecond busy timeout. In WAL mode, SQLite supports concurrent readers while writes execute safely, providing zero-configuration, sub-millisecond local speed. Furthermore, because our entire persistence tier is written using SQLAlchemy 2.0 ORM, the architecture is 100% engine-agnostic: by changing a single environment variable `DB_URL`, the platform connects to a high-concurrency PostgreSQL cluster in production with zero code changes."*

### Question 2: *"How exactly does your defense conflict engine detect collisions?"*
* **Defensible Answer:**
  > *"When a coordinator attempts to schedule a defense hearing with a proposed `(start_time, end_time)` on a specific date, `DefenseService` executes a three-way interval overlap query:
  > 1. It checks if the designated examination room is booked during that interval: `existing.start < new.end AND existing.end > new.start`.
  > 2. It checks if the defending team is already scheduled for another hearing.
  > 3. It checks if any appointed panelist—whether Chair, Internal Examiner, or External Examiner—is scheduled on a concurrent defense panel.
  > If any overlap is found, the transaction is rejected immediately with an HTTP 409 Conflict error identifying the exact conflicting room or professor."*

### Question 3: *"Why is proposal versioning immutable, and how is it implemented?"*
* **Defensible Answer:**
  > *"In university research, tracking how a student addressed supervisor critique is vital for academic integrity. Rather than overwriting proposal text in a single row, we created two separate entities: `Proposal` and `ProposalVersion`. When a supervisor requests revisions, the proposal status becomes `CHANGES_REQUESTED`. The student submits their edits alongside a `change_summary`, creating a new `ProposalVersion` row with incremented version number. Earlier versions remain untouched, giving supervisors a permanent historical record of student progress."*

### Question 4: *"What prevents students from falsifying submission times or claiming they submitted on time?"*
* **Defensible Answer:**
  > *"Milestone deadlines are strictly validated on the server. When a deliverable request reaches FastAPI, the server captures the authoritative UTC timestamp from the backend host clock and compares it with the `Milestone.deadline`. If `server_timestamp > deadline`, the backend permanently sets `is_late = True`. Client device clocks, browser timezones, or manipulated network packets have zero influence over the late flag."*

### Question 5: *"If GoRouter blocks unauthorized students on the mobile screen, is the app secure?"*
* **Defensible Answer:**
  > *"No, sir. Client-side route guards in Flutter are purely a user experience convenience. Real security lives on the backend. Every FastAPI endpoint executes role-based dependency checks (`require_roles_mobile(...)`) that inspect cryptographically signed JWT claims. Even if a malicious actor bypassed the mobile interface using Postman or cURL, the backend returns an immediate HTTP 403 Forbidden."*

### Question 6: *"How do you handle expired JWT tokens on the mobile app without logging the user out?"*
* **Defensible Answer:**
  > *"We implement dual-token authentication. The mobile client stores the short-lived access token and long-lived refresh token in the hardware-encrypted Android Keystore using `flutter_secure_storage`. Our Dio HTTP client uses a `QueuedInterceptor`. When an API call receives an HTTP 401, the interceptor pauses outgoing traffic, calls `/auth/refresh` with the refresh token, writes the newly issued tokens to hardware storage, and automatically retries the original request seamlessly without interrupting the user."*

---

## Tips for Presentation Day
1. **Pacing:** Speak at approximately 130 to 140 words per minute. Do not rush through the diagrams.
2. **Body Language:** Look directly at Course Teacher Tanvir Ahmed and the committee members. Gesture towards the screen when referencing the architecture and workflow diagrams.
3. **Live Demonstration Fallback:** Mention that the mobile app is compiled into a standalone 20.86 MB ARM64 APK and that all 72 automated test cases pass with a 100% verification rate.
