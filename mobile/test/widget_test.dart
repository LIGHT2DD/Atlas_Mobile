import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_mobile/shared/widgets/atlas_card.dart';
import 'package:atlas_mobile/shared/widgets/empty_state.dart';
import 'package:atlas_mobile/shared/widgets/loading_indicator.dart';
import 'package:atlas_mobile/shared/widgets/status_badge.dart';

void main() {
  group('ATLAS Widget UI Tests', () {
    testWidgets('StatusBadge renders appropriate label and color styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'approved'),
                StatusBadge(status: 'rejected'),
                StatusBadge(status: 'pending'),
                StatusBadge(status: 'completed'),
                StatusBadge(status: 'scheduled'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
    });

    testWidgets('AtlasCard renders child content within styled container and responds to taps', (WidgetTester tester) async {
      bool cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AtlasCard(
              onTap: () {
                cardTapped = true;
              },
              child: const Text('Card Content Test'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content Test'), findsOneWidget);
      await tester.tap(find.text('Card Content Test'));
      await tester.pump();
      expect(cardTapped, isTrue);
    });

    testWidgets('EmptyState displays title, message, and triggers action button', (WidgetTester tester) async {
      bool actionTapped = false;
      bool secondaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Empty State Title',
              message: 'Detailed description message',
              actionLabel: 'Primary Action',
              onAction: () {
                actionTapped = true;
              },
              secondaryActionLabel: 'Secondary Action',
              onSecondaryAction: () {
                secondaryTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Empty State Title'), findsOneWidget);
      expect(find.text('Detailed description message'), findsOneWidget);
      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.text('Secondary Action'), findsOneWidget);

      await tester.tap(find.text('Primary Action'));
      await tester.pump();
      expect(actionTapped, isTrue);

      await tester.tap(find.text('Secondary Action'));
      await tester.pump();
      expect(secondaryTapped, isTrue);
    });

    testWidgets('LoadingIndicator renders message and progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Authenticating credentials...'),
          ),
        ),
      );

      expect(find.text('Authenticating credentials...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
