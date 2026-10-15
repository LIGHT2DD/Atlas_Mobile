# ATLAS Role-Based Access Control (RBAC) Specification

ATLAS strictly defines and enforces three primary user roles:
1. **STUDENT**
2. **SUPERVISOR**
3. **COORDINATOR** (administrative role)

RBAC is enforced authoritatively at the **FastAPI service and dependency layers**. Unauthorized direct API calls or manual URL access return `403 Forbidden` or `401 Unauthorized`.

---

## Role Permission Matrix

| Feature / Resource | Student | Supervisor | Coordinator | Enforcement Method |
|---|:---:|:---:|:---:|---|
| **Semester Setup & Term Activation** | ❌ | ❌ | ✅ | `_require_coordinator` |
| **User Activation / Deactivation** | ❌ | ❌ | ✅ | `_require_coordinator` |
| **Team Formation (Create / Join / Invite)** | ✅ | ❌ | ❌ | `_require_student` |
| **Request Supervisor** | ✅ (Leader only) | ❌ | ❌ | `TeamService.request_supervisor` |
| **Accept / Decline Supervision Request** | ❌ | ✅ | ❌ | `_require_supervisor` + Request Ownership |
| **Administrative Supervisor Assignment** | ❌ | ❌ | ✅ | `_require_coordinator` |
| **Create Proposal Draft** | ✅ (Team member) | ❌ | ❌ | `ProposalService.get_or_create_draft` |
| **Submit / Resubmit Proposal** | ✅ (Team member) | ❌ | ❌ | `ProposalService.submit_proposal` |
| **Review & Approve / Reject Proposal** | ❌ | ✅ (Assigned only) | ✅ (Admin override) | `ProposalService.review_proposal` |
| **Create Milestone Deliverable** | ❌ | ❌ | ✅ | `_require_coordinator` |
| **Submit Milestone Deliverable** | ✅ (Team member) | ❌ | ❌ | `SubmissionService.create_submission` |
| **Grade Deliverable & Leave Feedback** | ❌ | ✅ (Assigned only) | ✅ (Admin override) | `SubmissionService.grade_submission` |
| **Schedule Oral Defense** | ❌ | ❌ | ✅ | `_require_coordinator` |
| **Submit Defense Rubric Scores** | ❌ | ✅ (Panel member) | ✅ | `EvaluationService.submit_evaluation` |
| **Configure Rubrics & Criteria Weights**| ❌ | ❌ | ✅ | `_require_coordinator` |
| **Publish Final Grades** | ❌ | ❌ | ✅ | `_require_coordinator` |
| **Export Academic CSV Reports** | ❌ | ❌ | ✅ | `_require_coordinator` |
| **View Audit Logs** | ❌ | ❌ | ✅ | `_require_coordinator` |
| **View Personal Team Grade** | ✅ (When published) | ✅ | ✅ | `EvaluationService` |

---

## Technical RBAC Implementation

### 1. Route-Level Role Guards
Defined in `api/v1/routes/dashboard/helpers.py`:
```python
def _require_coordinator(request: Request):
    user = _get_user(request)
    if not (user and user.role in (UserRole.COORDINATOR.value, UserRole.ADMIN.value)):
        raise HTTPException(status_code=403, detail="Coordinator authorization required.")
    return user

def _require_supervisor(request: Request):
    user = _get_user(request)
    if not (user and user.role == UserRole.SUPERVISOR.value):
        raise HTTPException(status_code=403, detail="Supervisor authorization required.")
    return user

def _require_student(request: Request):
    user = _get_user(request)
    if not (user and user.role == UserRole.STUDENT.value):
        raise HTTPException(status_code=403, detail="Student authorization required.")
    return user
```

### 2. Service-Level Entity Ownership Guards
Prevents cross-tenant or unauthorized entity modification even if a user has the correct role.
Example in `SubmissionService.grade_submission`:
```python
if team and team.supervisor_id != reviewer_id and not reviewer.is_coordinator:
    raise HTTPException(
        status_code=403,
        detail="Only assigned supervisor or coordinator can grade this submission."
    )
```

Example in `TeamService.request_supervisor`:
```python
is_leader = any(m.user_id == student_id and m.role == TeamRole.LEADER.value for m in team.members)
if not is_leader:
    raise HTTPException(status_code=403, detail="Only the team leader can request a supervisor.")
```

### 3. Dynamic Navigation
In `frontend/app/components/sidebar.html`, navigation items are conditionally rendered based on `current_user.role`. Attempting to access an administrative URL (e.g. `/dashboard/semesters/new` or `/dashboard/rubrics/new`) without the Coordinator role immediately triggers a backend `403 Forbidden` response.
