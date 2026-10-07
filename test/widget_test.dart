import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickr/main.dart';
import 'package:pickr/persistence/pick_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> openSheet(WidgetTester tester, {PickStore? store}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PickrApp(store: store ?? MemoryPickStore()));
    await tester.pumpAndSettle();
  }

  Future<void> jumpTo(WidgetTester tester, int week) async {
    await tester.tap(find.byKey(const Key('week-menu')));
    await tester.pumpAndSettle();
    final item = find.byKey(Key('jump-$week'));
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  Future<void> swipe(
    WidgetTester tester,
    Offset delta, {
    required Finder from,
  }) async {
    final gesture = await tester.startGesture(tester.getCenter(from));
    await gesture.moveBy(delta);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('fresh install opens on week 1 and keeps week 5 closed', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.byKey(const Key('sheet')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 1',
    );
    expect(find.byKey(const Key('dot-1')), findsOneWidget);
    expect(find.byKey(const Key('dot-18')), findsOneWidget);
    expect(find.text('Enter the team you picked for Week 1'), findsOneWidget);
    expect(
      find.text('Still open: Week 1, Week 2, Week 3, Week 4'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('next-week')));
    await tester.pumpAndSettle();
    expect(
      find.text('Pick a team for Week 1 before moving on.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 1',
    );

    await swipe(
      tester,
      const Offset(-220, 0),
      from: find.byKey(const Key('week-instruction')),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 1',
    );

    await jumpTo(tester, 5);
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 5',
    );
    expect(
      find.text('Week 5 stays closed until Weeks 1–4 are filled in.'),
      findsOneWidget,
    );
    expect(
      find.text('Still open: Week 1, Week 2, Week 3, Week 4'),
      findsOneWidget,
    );

    final seahawks = find.byKey(const Key('team-SEA'));
    await tester.scrollUntilVisible(seahawks, 400);
    await tester.tap(seahawks);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('the week menu jumps ahead without a pick', (tester) async {
    await openSheet(tester);
    await jumpTo(tester, 12);
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 12',
    );
    expect(
      find.text(
        "Matchups and spreads for Week 12 aren't posted yet. "
        "You can look ahead, but there's nothing to pick.",
      ),
      findsOneWidget,
    );
    expect(find.byType(InkWell), findsWidgets);
    expect(find.byKey(const Key('team-SEA')), findsNothing);
  });

  testWidgets('a loss still lets the next week open, and a win shows a check', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.byKey(const Key('team-NE')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('team-NE')),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('next-week')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 2',
    );

    // Week 2 has no pick, so the arrow will not leave it. The menu can.
    await jumpTo(tester, 1);
    await tester.tap(find.byKey(const Key('team-SEA')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('team-SEA')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.close), findsNothing);

    await swipe(
      tester,
      const Offset(-220, 0),
      from: find.byKey(const Key('week-instruction')),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 2',
    );
  });

  testWidgets('swipe on a team button does not change the week', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.byKey(const Key('team-SEA')));
    await tester.pumpAndSettle();

    await swipe(
      tester,
      const Offset(-220, 0),
      from: find.byKey(const Key('team-SEA')),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 1',
    );

    await swipe(
      tester,
      const Offset(-220, 0),
      from: find.byKey(const Key('week-menu')),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 1',
    );
  });

  testWidgets('a used team stays on the card and cannot be tapped', (
    tester,
  ) async {
    await openSheet(tester, store: MemoryPickStore({1: 'SEA'}));
    await jumpTo(tester, 2);

    final card = find.byKey(const Key('game-SEA-ARI'));
    await tester.scrollUntilVisible(card, 400);
    await tester.pumpAndSettle();

    expect(card, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('team-SEA')),
        matching: find.text('USED'),
      ),
      findsOneWidget,
    );
    expect(find.text(usedFooter), findsOneWidget);

    await tester.tap(find.byKey(const Key('team-SEA')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('team-ARI')));
    await tester.tap(find.byKey(const Key('team-ARI')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('team-ARI')),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a game is hidden only when both teams were already used', (
    tester,
  ) async {
    await openSheet(tester, store: MemoryPickStore({1: 'ATL', 2: 'GB'}));
    await jumpTo(tester, 3);

    expect(find.byKey(const Key('game-ATL-GB')), findsNothing);
    expect(find.byKey(const Key('team-ATL')), findsNothing);
    expect(find.byKey(const Key('team-GB')), findsNothing);
    expect(find.byKey(const Key('game-LAC-BUF')), findsOneWidget);
    expect(find.text(usedFooter), findsOneWidget);
  });

  testWidgets('week 6 is not posted and cannot be picked', (tester) async {
    await openSheet(tester);
    await jumpTo(tester, 6);
    expect(
      find.text(
        "Matchups and spreads for Week 6 aren't posted yet. "
        "You can look ahead, but there's nothing to pick.",
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('matchup-list')), findsNothing);
  });

  testWidgets('week 5 shows week 4 records, results, and the away spread', (
    tester,
  ) async {
    await openSheet(tester);
    await jumpTo(tester, 5);

    expect(find.text('London'), findsOneWidget);

    final card = find.byKey(const Key('game-SF-SEA'));
    await tester.scrollUntilVisible(card, 400);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: card,
        matching: find.textContaining('Seahawks (3-1)'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('49ers (4-0)')),
      findsOneWidget,
    );
    expect(find.descendant(of: card, matching: find.text('3')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('at')), findsWidgets);
    expect(find.text('W 30-23 at home'), findsOneWidget);
    expect(find.text('L 31-33 at Commanders'), findsOneWidget);
    expect(find.text('W 24-14 at home'), findsOneWidget);
    expect(find.textContaining('FINAL'), findsNothing);
  });

  testWidgets('every posted week lays out on a phone', (tester) async {
    await openSheet(tester);
    for (var week = 1; week <= 18; week++) {
      await jumpTo(tester, week);
      final list = find.byKey(const Key('matchup-list'));
      if (list.evaluate().isEmpty) continue;
      for (var pass = 0; pass < 8; pass++) {
        await tester.drag(list, const Offset(0, -700));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }
  });

  testWidgets('picks survive a restart and clear wipes them', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await openSheet(tester, store: SharedPreferencesPickStore());

    await tester.tap(find.byKey(const Key('team-SEA')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openSheet(tester, store: SharedPreferencesPickStore());
    expect(
      find.descendant(
        of: find.byKey(const Key('team-SEA')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('clear-picks')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-clear')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 1',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openSheet(tester, store: SharedPreferencesPickStore());
    expect(find.byIcon(Icons.check), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 1',
    );
  });
}

const String usedFooter =
    "A team you've already used can't be picked again. "
    'A game is hidden only when both teams are used.';
