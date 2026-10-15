# ATLAS Lifecycle Workflows

ATLAS governs the entire university thesis and capstone lifecycle across 12 distinct sequential stages.

---

## The 12-Stage Lifecycle

```
Stage 1:  Semester Setup
               ↓
Stage 2:  Team Formation
               ↓
Stage 3:  Supervisor Request
               ↓
Stage 4:  Supervisor Assignment
               ↓
Stage 5:  Proposal Creation (Draft)
               ↓
Stage 6:  Proposal Submission (v1)
               ↓
Stage 7:  Proposal Review (Supervisor: Approve / Request Changes)
               ↓
Stage 8:  Changes & Resubmission (v2, v3...)
               ↓
Stage 9:  Proposal Approval
               ↓
Stage 10: Milestone Submissions (SRS, Midterm, Final Code, Report)
               ↓
Stage 11: Oral Defense Scheduling & Evaluation
               ↓
Stage 12: Final Grade Calculation & Publication
```

---

## Detailed Stage Workflows

### 1. Semester Setup
- **Actor:** Coordinator
- **Action:** Sets up the academic year (e.g. `2026-2027`), semester dates, and team size boundaries (`min_team_size`, `max_team_size`).
- **Effect:** All subsequent teams, milestones, and rubric criteria are scoped to this active semester.

### 2. Team Formation
- **Actor:** Student
- **Action:** A student forms a team and enters a preliminary project title. The creator is designated as `LEADER`.
- **Invites:** A unique 6-character uppercase alphanumeric code (e.g. `X7K9LP`) is generated. Peer students join using this code.
- **Rule:** A student cannot belong to more than one active team.

### 3. Supervisor Request
- **Actor:** Student Team Leader
- **Action:** Browses eligible faculty members and submits a formal supervision request with project notes.
- **Rule:** A team may only have one active supervisor request at a time.

### 4. Supervisor Assignment
- **Actor:** Supervisor or Coordinator
- **Supervisor Workflow:** Receives notification; reviews request in `/dashboard/requests`; accepts or declines. Upon acceptance, `team.supervisor_id` is set and team status advances to `SUPERVISOR_ASSIGNED`.
- **Administrative Override:** Coordinator can directly assign or reassign supervisors at any time.

### 5-9. Proposal Workflow & State Machine
```
[ DRAFT ]  <--- Student edits title & abstract
    |
    v (Student submits)
[ SUBMITTED ] (Version 1 recorded)
    |
    +---> [ CHANGES_REQUESTED ] (Supervisor feedback recorded)
    |            |
    |            v (Student resubmits with change summary)
    |     [ SUBMITTED ] (Version 2 recorded)
    |            |
    +---> [ APPROVED ]  <--- Supervisor approves; team status advances
    |
    +---> [ REJECTED ]
```
- **Auditing:** Every submission creates an immutable `ProposalVersion` snapshot. All feedback and supervisor decisions are archived as `ProposalReview` entries.

### 10. Milestone Deliverables
- **Actor:** Coordinator configures milestones (e.g. SRS, Midterm Architecture, Final Code Repository, Final Report) with explicit due dates and weights.
- **Submission:** Students upload files or enter code repository URLs.
- **Server-Side Late Detection:** Submissions past deadline are automatically marked as `LATE` by the server.
- **Grading:** Assigned supervisor reviews submissions and assigns scores and written feedback.

### 11. Defense Scheduling & Conflict Detection
- **Actor:** Coordinator
- **Action:** Selects team, date, room, time slot, and panel members (Chair, Internal Members, External).
- **Conflict Prevention Engine:** Validates that:
  - The room is not booked by another defense during overlapping times.
  - No panel member is scheduled to evaluate in another room simultaneously.
  - The team does not have another scheduled defense.

### 12. Evaluation & Final Grade Publication
- **Actor:** Defense Panel Members & Coordinator
- **Grading:** Panel members enter scores across configured semester rubric criteria (e.g. Problem Definition 10%, Implementation 25%, Defense/Viva 20%).
- **Weighted Calculation:** The server computes the authoritative score:
  $$\text{Final Score} = \sum \left( \frac{\text{Score}_i}{\text{MaxScore}_i} \times \text{Weight}_i \right)$$
- **Grade Mapping:** Authoritative mapping:
  - $\ge 90\% \rightarrow \text{A+}$
  - $\ge 85\% \rightarrow \text{A}$
  - $\ge 80\% \rightarrow \text{A-}$
  - $\ge 75\% \rightarrow \text{B+}$
  - $\ge 70\% \rightarrow \text{B}$
  - $\ge 65\% \rightarrow \text{B-}$
  - $\ge 60\% \rightarrow \text{C+}$
  - $\ge 50\% \rightarrow \text{C}$
  - $< 50\% \rightarrow \text{F}$
- **Publication:** Coordinator reviews final calculated grades and clicks **Publish Grade**. Team status transitions to `COMPLETED`, and students receive immediate notification.
