import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_mobile/shared/models/user_model.dart';
import 'package:atlas_mobile/shared/models/team_model.dart';
import 'package:atlas_mobile/shared/models/proposal_model.dart';
import 'package:atlas_mobile/shared/models/milestone_model.dart';
import 'package:atlas_mobile/shared/models/defense_model.dart';
import 'package:atlas_mobile/shared/models/evaluation_model.dart';
import 'package:atlas_mobile/shared/models/notification_model.dart';
import 'package:atlas_mobile/features/supervisor/supervisor_repository.dart';
import 'package:atlas_mobile/features/coordinator/coordinator_repository.dart';

void main() {
  group('ATLAS Data Models Unit Tests', () {
    test('UserModel JSON parsing and role checking', () {
      final json = {
        'id': 'usr-123',
        'email': 'student@atlas.edu',
        'first_name': 'Alice',
        'last_name': 'Smith',
        'role': 'student',
        'is_active': true,
        'department': 'Computer Science',
        'student_id': 'CS-2026-001',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr-123');
      expect(user.email, 'student@atlas.edu');
      expect(user.fullName, 'Alice Smith');
      expect(user.role, UserRole.student);
      expect(user.role.isStudent, isTrue);
      expect(user.role.isSupervisor, isFalse);
      expect(user.role.isCoordinator, isFalse);
    });

    test('TeamModel JSON parsing with roster and supervisor', () {
      final json = {
        'id': 'team-99',
        'name': 'Quantum Labs',
        'project_title': 'Quantum Cryptography Protocol',
        'description': 'Post-quantum key exchange',
        'status': 'forming',
        'invite_code': 'QNT123',
        'leader_id': 'usr-1',
        'is_leader': true,
        'supervisor': {
          'id': 'sup-1',
          'name': 'Dr. Robert Oppenheimer',
          'email': 'oppenheimer@atlas.edu',
        },
        'members': [
          {
            'id': 'tm-1',
            'user_id': 'usr-1',
            'name': 'Alice',
            'email': 'alice@atlas.edu',
            'role': 'leader',
          },
          {
            'id': 'tm-2',
            'user_id': 'usr-2',
            'name': 'Bob',
            'email': 'bob@atlas.edu',
            'role': 'member',
          }
        ],
        'grade_published': false,
      };

      final team = TeamModel.fromJson(json);

      expect(team.id, 'team-99');
      expect(team.name, 'Quantum Labs');
      expect(team.isLeader, isTrue);
      expect(team.supervisor, isNotNull);
      expect(team.supervisor!.name, 'Dr. Robert Oppenheimer');
      expect(team.members.length, 2);
      expect(team.members.first.role, 'leader');
    });

    test('ProposalModel JSON parsing with version history', () {
      final json = {
        'id': 'prop-1',
        'team_id': 'team-99',
        'team_name': 'Quantum Labs',
        'title': 'Quantum Key Distribution',
        'abstract': 'Theoretical study of BB84 security',
        'status': 'approved',
        'current_version': 2,
        'versions': [
          {
            'id': 'v-1',
            'version_number': 1,
            'title': 'Quantum Key Distribution Draft',
            'submitted_by_name': 'Alice',
          },
          {
            'id': 'v-2',
            'version_number': 2,
            'title': 'Quantum Key Distribution Final',
            'submitted_by_name': 'Alice',
          }
        ],
        'reviews': [
          {
            'id': 'rev-1',
            'reviewer_name': 'Dr. Robert Oppenheimer',
            'decision': 'approved',
            'comments': 'Excellent methodology and clear goals.',
          }
        ],
      };

      final proposal = ProposalModel.fromJson(json);

      expect(proposal.id, 'prop-1');
      expect(proposal.currentVersion, 2);
      expect(proposal.status, 'approved');
      expect(proposal.versions.length, 2);
      expect(proposal.reviews.length, 1);
      expect(proposal.reviews.first.decision, 'approved');
    });

    test('MilestoneModel & SubmissionModel parsing', () {
      final msJson = {
        'id': 'ms-1',
        'title': 'Midterm Report',
        'max_score': 100.0,
        'weight_percentage': 25.0,
        'status': 'active',
        'is_overdue': false,
      };

      final milestone = MilestoneModel.fromJson(msJson);
      expect(milestone.title, 'Midterm Report');
      expect(milestone.maxScore, 100.0);
      expect(milestone.weightPercentage, 25.0);

      final subJson = {
        'id': 'sub-1',
        'title': 'Midterm Architecture Paper',
        'milestone_id': 'ms-1',
        'team_id': 'team-99',
        'submitted_by_name': 'Alice',
        'version': 1,
        'is_late': false,
        'status': 'graded',
        'score': 94.5,
        'feedback': 'Very well argued.',
      };

      final sub = SubmissionModel.fromJson(subJson);
      expect(sub.score, 94.5);
      expect(sub.isLate, isFalse);
      expect(sub.status, 'graded');
    });

    test('DefenseModel parsing with conflict and panel members', () {
      final json = {
        'id': 'def-1',
        'team_id': 'team-99',
        'team_name': 'Quantum Labs',
        'project_title': 'Quantum Key Distribution',
        'date': '2026-11-20',
        'start_time': '10:00',
        'end_time': '11:00',
        'room': 'Hall 101',
        'status': 'scheduled',
        'panel_members': [
          {
            'id': 'pm-1',
            'user_id': 'usr-f1',
            'name': 'Dr. Alan Turing',
            'role': 'chair',
          },
          {
            'id': 'pm-2',
            'user_id': 'usr-f2',
            'name': 'Dr. Claude Shannon',
            'role': 'examiner',
          }
        ],
      };

      final defense = DefenseModel.fromJson(json);
      expect(defense.room, 'Hall 101');
      expect(defense.panelMembers.length, 2);
      expect(defense.panelMembers.first.name, 'Dr. Alan Turing');
    });

    test('EvaluationModel & TeamGradeModel parsing', () {
      final rubricJson = {
        'id': 'rub-1',
        'title': 'Technical Rigor',
        'max_score': 30.0,
        'weight_percentage': 30.0,
        'order_index': 1,
      };

      final rubric = RubricCriteriaModel.fromJson(rubricJson);
      expect(rubric.title, 'Technical Rigor');
      expect(rubric.maxScore, 30.0);

      final gradeJson = {
        'has_grade': true,
        'team_name': 'Quantum Labs',
        'project_title': 'Quantum Key Distribution',
        'final_grade': 'A+',
        'final_score': 96.2,
        'published': true,
      };

      final grade = TeamGradeModel.fromJson(gradeJson);
      expect(grade.finalGrade, 'A+');
      expect(grade.published, isTrue);
      expect(grade.finalScore, 96.2);
    });

    test('NotificationModel parsing', () {
      final notifJson = {
        'id': 'nt-1',
        'title': 'Proposal Approved',
        'content': 'Your thesis proposal has been officially approved.',
        'type': 'proposal',
        'is_read': false,
      };

      final notif = NotificationModel.fromJson(notifJson);
      expect(notif.title, 'Proposal Approved');
      expect(notif.isRead, isFalse);
      expect(notif.type, 'proposal');
    });

    test('SupervisorRequestItem parsing handles full and null fields gracefully', () {
      final json = {
        'id': 'req-101',
        'team_id': 'team-1',
        'team_name': 'Neural Nexus',
        'project_title': 'Medical AI',
        'requested_by_name': 'Tahmid Hasan',
        'message': 'Please supervise our research.',
        'status': 'pending',
      };
      final item = SupervisorRequestItem.fromJson(json);
      expect(item.id, equals('req-101'));
      expect(item.teamName, equals('Neural Nexus'));
      expect(item.requestedByName, equals('Tahmid Hasan'));
      expect(item.status, equals('pending'));
    });

    test('SemesterModel parsing handles active flag and dates', () {
      final json = {
        'id': 'sem-fa26',
        'name': 'Fall 2026',
        'code': 'FA26',
        'start_date': '2026-09-01',
        'end_date': '2026-12-31',
        'is_active': true,
      };
      final sem = SemesterModel.fromJson(json);
      expect(sem.id, equals('sem-fa26'));
      expect(sem.code, equals('FA26'));
      expect(sem.isActive, isTrue);
    });

    test('AuditLogItem parsing sets fallback userName when missing', () {
      final json = {
        'id': 'log-99',
        'action': 'CREATED_TEAM',
        'resource_type': 'team',
      };
      final log = AuditLogItem.fromJson(json);
      expect(log.id, equals('log-99'));
      expect(log.userName, equals('System'));
      expect(log.action, equals('CREATED_TEAM'));
    });

    test('ReportSummaryModel parsing calculates correct counter aggregates', () {
      final json = {
        'total_students': 24,
        'total_supervisors': 5,
        'total_teams': 8,
        'active_proposals': 8,
        'completed_defenses': 6,
        'teams_by_status': {'completed': 4, 'pending': 4},
      };
      final report = ReportSummaryModel.fromJson(json);
      expect(report.totalStudents, equals(24));
      expect(report.totalSupervisors, equals(5));
      expect(report.totalTeams, equals(8));
      expect(report.teamsByStatus['completed'], equals(4));
    });

    test('TeamMemberModel parses leader role accurately', () {
      final json = {
        'id': 'tm-1',
        'user_id': 'u-1',
        'name': 'Tahmid Hasan',
        'email': 'student1@atlas.edu',
        'role': 'leader',
      };
      final member = TeamMemberModel.fromJson(json);
      expect(member.name, equals('Tahmid Hasan'));
      expect(member.role, equals('leader'));
    });

    test('SupervisorInfo parsing maps id, name, and email', () {
      final json = {
        'id': 'sup-1',
        'name': 'Fatema Jannat Dihan',
        'email': 'supervisor1@atlas.edu',
      };
      final sup = SupervisorInfo.fromJson(json);
      expect(sup.id, equals('sup-1'));
      expect(sup.name, equals('Fatema Jannat Dihan'));
    });

    test('PanelMemberModel maps examiner panel assignments', () {
      final json = {
        'id': 'pm-1',
        'user_id': 'u-sup-1',
        'name': 'Fatema Jannat Dihan',
        'role': 'lead_evaluator',
      };
      final panel = PanelMemberModel.fromJson(json);
      expect(panel.role, equals('lead_evaluator'));
      expect(panel.name, equals('Fatema Jannat Dihan'));
    });

    test('EvaluationScoreModel computes criteria scores', () {
      final json = {
        'criteria_id': 'crit-1',
        'criteria_title': 'Literature Review',
        'score': 24.5,
        'max_score': 25.0,
      };
      final score = EvaluationScoreModel.fromJson(json);
      expect(score.score, equals(24.5));
      expect(score.maxScore, equals(25.0));
      expect(score.criteriaTitle, equals('Literature Review'));
    });

    test('ProposalVersionModel parses version number and changeSummary', () {
      final json = {
        'id': 'ver-2',
        'version_number': 2,
        'title': 'Autonomous Medical Diagnosis',
        'abstract_text': 'Detailed abstract text here...',
        'change_summary': 'Added ROC curves',
        'submitted_by_name': 'Tahmid Hasan',
        'submitted_at': '2026-09-15T10:00:00Z',
      };
      final ver = ProposalVersionModel.fromJson(json);
      expect(ver.versionNumber, equals(2));
      expect(ver.changeSummary, equals('Added ROC curves'));
    });
  });
}
