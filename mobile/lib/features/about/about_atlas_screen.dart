import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../widgets/neumorphic/neumorphic.dart';

class AboutAtlasScreen extends ConsumerWidget {
  const AboutAtlasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: const NeuAppBar(title: 'About ATLAS'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // Header Card with Logo and Title
          IosNeuCard(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                NeuContainer(
                  shape: BoxShape.circle,
                  width: 72,
                  height: 72,
                  depthType: NeuDepth.convex,
                  depth: 3.5,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(6),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/play_store_512.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ATLAS',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: neuTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Academic Thesis Lifecycle & Assessment Suite',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: neuTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: neuTheme.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version 1.0.0 • Production Build',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: neuTheme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'A unified academic suite designed to modernize, coordinate, and evaluate student thesis and capstone projects from initial proposal through final oral defense.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: neuTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Purpose & Mission Card
          IosNeuCard(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(TablerIcons.target, color: neuTheme.accentColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Purpose & Mission',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: neuTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _featureItem(
                  context,
                  icon: TablerIcons.cloud_lock,
                  title: 'Centralized Digital Records',
                  description: 'Replaces scattered spreadsheets and paper forms with a single secure source of truth.',
                ),
                const SizedBox(height: 12),
                _featureItem(
                  context,
                  icon: TablerIcons.timeline,
                  title: 'Clear Milestone Progression',
                  description: 'Keeps students and supervisors aligned on deadlines, document deliverables, and revisions.',
                ),
                const SizedBox(height: 12),
                _featureItem(
                  context,
                  icon: TablerIcons.scale,
                  title: 'Objective Rubric Grading',
                  description: 'Standardizes evaluation criteria across committee members for fair and auditable grading.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Who Uses ATLAS? (Role Breakdown)
          IosNeuCard(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(TablerIcons.users, color: neuTheme.accentColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Roles & Capabilities',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: neuTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _roleItem(
                  context,
                  badge: 'STUDENT',
                  badgeColor: const Color(0xFF3182CE),
                  title: 'Research Team Member',
                  description: 'Form teams, submit thesis proposals, upload milestone documents, view feedback, and check defense scores.',
                ),
                const SizedBox(height: 14),
                _roleItem(
                  context,
                  badge: 'SUPERVISOR',
                  badgeColor: const Color(0xFF38A169),
                  title: 'Academic Advisor & Mentor',
                  description: 'Review research topics, request proposal revisions, track progress deliverables, and guide research teams.',
                ),
                const SizedBox(height: 14),
                _roleItem(
                  context,
                  badge: 'COORDINATOR',
                  badgeColor: const Color(0xFF805AD5),
                  title: 'Department Administrator',
                  description: 'Oversee academic semesters, assign supervisors, schedule oral defense panels, and publish final grades.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Core Lifecycle Workflow
          IosNeuCard(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(TablerIcons.route, color: neuTheme.accentColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Lifecycle Workflow',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: neuTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _stepRow(context, step: '1', title: 'Proposal & Topic Approval', desc: 'Team formation, supervisor assignment, and formal committee acceptance.'),
                const SizedBox(height: 10),
                _stepRow(context, step: '2', title: 'Milestones & Submissions', desc: 'Draft submissions, progress reports, and structured qualitative feedback.'),
                const SizedBox(height: 10),
                _stepRow(context, step: '3', title: 'Oral Defense Scheduling', desc: 'Panel composition, presentation room allocation, and timetable publishing.'),
                const SizedBox(height: 10),
                _stepRow(context, step: '4', title: 'Rubric Evaluation & Grades', desc: 'Multi-criteria scoring, weighted aggregation, and verified mark release.'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Technical Architecture
          IosNeuCard(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(TablerIcons.device_laptop, color: neuTheme.accentColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Technical Architecture',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: neuTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _techRow(context, label: 'Client Framework', value: 'Flutter 3 (Dart) + Riverpod'),
                _techRow(context, label: 'Backend Server', value: 'FastAPI (Python 3.12, Uvicorn)'),
                _techRow(context, label: 'Database & ORM', value: 'SQLAlchemy (SQLite WAL / PostgreSQL)'),
                _techRow(context, label: 'Authentication', value: 'Dual-Token JWT + Database Refresh'),
                _techRow(context, label: 'Notifications', value: 'Firebase Cloud Messaging (FCM)'),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Institutional Footer
          Center(
            child: Column(
              children: [
                Text(
                  'ATLAS — Academic Thesis Lifecycle & Assessment Suite',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: neuTheme.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Designed for higher-education departments and engineering faculties.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: neuTheme.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _featureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final neuTheme = context.neuTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: neuTheme.accentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: neuTheme.accentColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: neuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: neuTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleItem(
    BuildContext context, {
    required String badge,
    required Color badgeColor,
    required String title,
    required String description,
  }) {
    final neuTheme = context.neuTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: neuTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: neuTheme.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _stepRow(
    BuildContext context, {
    required String step,
    required String title,
    required String desc,
  }) {
    final neuTheme = context.neuTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: neuTheme.accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: neuTheme.accentColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: neuTheme.textPrimary,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11.5,
                  color: neuTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _techRow(BuildContext context, {required String label, required String value}) {
    final neuTheme = context.neuTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: neuTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: neuTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
