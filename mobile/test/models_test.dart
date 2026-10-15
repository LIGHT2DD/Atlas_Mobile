import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_mobile/shared/models/user_model.dart';
import 'package:atlas_mobile/shared/models/team_model.dart';
import 'package:atlas_mobile/shared/models/proposal_model.dart';
import 'package:atlas_mobile/shared/models/milestone_model.dart';
import 'package:atlas_mobile/shared/models/defense_model.dart';
import 'package:atlas_mobile/shared/models/evaluation_model.dart';
import 'package:atlas_mobile/shared/models/notification_model.dart';

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
  });
}
