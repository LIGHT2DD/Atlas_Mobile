import pytest
from fastapi import HTTPException
from api.v1.services.team import TeamService
from api.v1.services.proposal import ProposalService
from api.v1.models.proposal import ProposalStatus


def test_proposal_lifecycle_and_versioning(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    sup1 = seeded_users["supervisor1"]
    sem = seeded_users["semester"]

    # Create team & assign supervisor
    team = TeamService.create_team(
        db=db_session,
        student_id=stu1.id,
        name="Proposal Test Team",
        project_title="Edge ML Consensus",
        semester_id=sem.id,
    )
    team.supervisor_id = sup1.id
    db_session.commit()

    # 1. Draft
    prop = ProposalService.get_or_create_draft(
        db=db_session,
        team_id=team.id,
        student_id=stu1.id,
        title="Edge ML Consensus",
        abstract="Initial draft abstract.",
    )
    assert prop.status == ProposalStatus.DRAFT.value
    assert prop.current_version == 1

    # 2. Submit
    submitted_prop, v1 = ProposalService.submit_proposal(
        db=db_session,
        proposal_id=prop.id,
        student_id=stu1.id,
    )
    assert submitted_prop.status == ProposalStatus.SUBMITTED.value
    assert v1.version_number == 1

    # 3. Supervisor requests changes
    review1 = ProposalService.review_proposal(
        db=db_session,
        proposal_id=prop.id,
        reviewer_id=sup1.id,
        decision="changes_requested",
        comments="Please add security threat models.",
    )
    assert prop.status == ProposalStatus.CHANGES_REQUESTED.value

    # 4. Student resubmits new version (v2)
    submitted_v2, v2 = ProposalService.submit_proposal(
        db=db_session,
        proposal_id=prop.id,
        student_id=stu1.id,
        title="Edge ML Consensus - Revised",
        abstract="Expanded abstract with threat model.",
        change_summary="Added Section 4 threat model.",
    )
    assert submitted_v2.status == ProposalStatus.SUBMITTED.value
    assert submitted_v2.current_version == 2
    assert v2.version_number == 2

    # 5. Supervisor approves
    review2 = ProposalService.review_proposal(
        db=db_session,
        proposal_id=prop.id,
        reviewer_id=sup1.id,
        decision="approved",
        comments="Well revised. Approved to proceed.",
    )
    assert prop.status == ProposalStatus.APPROVED.value


def test_proposal_invalid_state_transition(db_session, seeded_users):
    stu1 = seeded_users["student1"]
    sup1 = seeded_users["supervisor1"]
    sem = seeded_users["semester"]

    team = TeamService.create_team(
        db=db_session,
        student_id=stu1.id,
        name="Invalid Transition Team",
        project_title="Invalid Transition Project",
        semester_id=sem.id,
    )
    team.supervisor_id = sup1.id
    db_session.commit()

    prop = ProposalService.get_or_create_draft(
        db=db_session,
        team_id=team.id,
        student_id=stu1.id,
        title="Invalid Transition Project",
    )
    assert prop.status == ProposalStatus.DRAFT.value

    # Attempting to approve while in DRAFT state must fail
    with pytest.raises(HTTPException) as exc:
        ProposalService.review_proposal(
            db=db_session,
            proposal_id=prop.id,
            reviewer_id=sup1.id,
            decision="approved",
            comments="Should fail",
        )
    assert exc.value.status_code == 400
    assert "Invalid state transition" in exc.value.detail
