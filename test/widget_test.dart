import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickr/main.dart';
import 'package:pickr/persistence/favorite_store.dart';
import 'package:pickr/persistence/pick_store.dart';
import 'package:pickr/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    PickStore? store,
    FavoriteStore? favorites,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      PickrApp(
        store: store ?? MemoryPickStore(),
        favorites: favorites ?? MemoryFavoriteStore(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dismissSnackBar(WidgetTester tester) async {
    final scaffold = find.byType(Scaffold);
    if (scaffold.evaluate().isEmpty) return;
    ScaffoldMessenger.of(tester.element(scaffold.first)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
  }

  Future<void> tapTeam(WidgetTester tester, String code) async {
    await dismissSnackBar(tester);
    final finder = find.byKey(Key('team-$code'));
    await tester.scrollUntilVisible(finder, 400);
    final rect = tester.getRect(finder);
    await tester.tapAt(Offset(rect.left + 16, rect.center.dy));
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

  bool teamIsSelected(WidgetTester tester, String code) {
    final materials = tester.widgetList<Material>(
      find.ancestor(
        of: find.byKey(Key('team-$code')),
        matching: find.byType(Material),
      ),
    );
    return materials.any((material) => material.color == AppColors.accent);
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

    expect(find.text('Clear'), findsNothing);
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
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 2',
    );
    expect(find.text("You haven't picked for Week 1 yet."), findsOneWidget);

    await tapTeam(tester, 'ARI');
    expect(teamIsSelected(tester, 'ARI'), isFalse);
    expect(find.text("You haven't picked for Week 1 yet."), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('prev-week')));
    await tester.pumpAndSettle();
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
      'Week 2',
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

    await tapTeam(tester, 'SEA');
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(teamIsSelected(tester, 'SEA'), isFalse);
    expect(
      find.text("You haven't picked for Week 1, Week 2, Week 3, Week 4 yet."),
      findsOneWidget,
    );
  });

  testWidgets('the week menu jumps ahead without a pick', (tester) async {
    await openSheet(tester);
    await jumpTo(tester, 12);
    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 12',
    );
    expect(find.byKey(const Key('matchup-list')), findsOneWidget);
    final missing = [
      for (var week = 1; week < 12; week++) 'Week $week',
    ].join(', ');
    expect(find.text("You haven't picked for $missing yet."), findsOneWidget);

    await tapTeam(tester, 'SEA');
    expect(teamIsSelected(tester, 'SEA'), isFalse);
    expect(find.text("You haven't picked for $missing yet."), findsNWidgets(2));
  });

  testWidgets('a loss still lets the next week open, and a win shows a check', (
    tester,
  ) async {
    await openSheet(tester);

    await tapTeam(tester, 'NE');
    expect(find.text('Enter the team you picked for Week 1'), findsNothing);
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

    await jumpTo(tester, 1);
    await tapTeam(tester, 'SEA');
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
      from: find.byKey(const Key('still-open')),
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
    await tapTeam(tester, 'SEA');

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

    await tapTeam(tester, 'SEA');
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);

    await tapTeam(tester, 'ARI');
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
    await tester.scrollUntilVisible(find.byKey(const Key('game-LAC-BUF')), 400);
    expect(find.byKey(const Key('game-LAC-BUF')), findsOneWidget);
    expect(find.text(usedFooter), findsOneWidget);
  });

  testWidgets('future weeks show matchups before earlier picks are in', (
    tester,
  ) async {
    await openSheet(tester);
    await jumpTo(tester, 5);
    await tester.tap(find.byKey(const Key('next-week')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('week-title'))).data,
      'Week 6',
    );
    final missing = [
      for (var week = 1; week < 6; week++) 'Week $week',
    ].join(', ');
    expect(find.text("You haven't picked for $missing yet."), findsOneWidget);
    expect(find.byKey(const Key('matchup-list')), findsOneWidget);
    expect(find.text('+10.5'), findsOneWidget);
    final london = find.byKey(const Key('game-HOU-JAX'));
    await tester.scrollUntilVisible(london, 400);
    expect(
      find.descendant(of: london, matching: find.text('London')),
      findsOneWidget,
    );
    final seattle = find.byKey(const Key('game-SEA-DEN'));
    await tester.scrollUntilVisible(seattle, 400);
    expect(
      find.descendant(of: seattle, matching: find.text('-1.5')),
      findsOneWidget,
    );

    await tapTeam(tester, 'SEA');
    expect(teamIsSelected(tester, 'SEA'), isFalse);
    expect(find.text("You haven't picked for $missing yet."), findsNWidgets(2));

    await jumpTo(tester, 7);
    final week7Missing = [
      for (var week = 1; week < 7; week++) 'Week $week',
    ].join(', ');
    expect(
      find.text("You haven't picked for $week7Missing yet."),
      findsOneWidget,
    );
    expect(find.text('—'), findsNothing);
    expect(find.text('at'), findsWidgets);
    await tester.scrollUntilVisible(find.text('France'), 400);
    expect(find.text('France'), findsOneWidget);
  });

  testWidgets('a caught-up sheet can look ahead but still cannot pick', (
    tester,
  ) async {
    await openSheet(
      tester,
      store: MemoryPickStore({1: 'NE', 2: 'GB', 3: 'KC', 4: 'DAL', 5: 'PHI'}),
    );
    await jumpTo(tester, 6);
    expect(find.byKey(const Key('still-open')), findsNothing);
    expect(
      find.text('Week 6 — look only, not open for picks.'),
      findsOneWidget,
    );

    await tapTeam(tester, 'SEA');
    expect(teamIsSelected(tester, 'SEA'), isFalse);
    expect(
      find.text('Week 6 — look only, not open for picks.'),
      findsNWidgets(2),
    );
  });

  testWidgets('week 5 shows week 4 records, results, and the away spread', (
    tester,
  ) async {
    await openSheet(tester);
    await jumpTo(tester, 5);

    await tester.scrollUntilVisible(find.text('London'), 400);
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
    expect(
      find.descendant(of: card, matching: find.text('+3')),
      findsOneWidget,
    );
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

  testWidgets('a favorite sorts above the spread and stays filled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await openSheet(
      tester,
      store: SharedPreferencesPickStore(),
      favorites: SharedPreferencesFavoriteStore(),
    );

    final jetsStar = find.byKey(const Key('favorite-NYJ'));
    await tester.scrollUntilVisible(jetsStar, 400);
    await tester.tap(jetsStar);
    await tester.pumpAndSettle();
    expect(teamIsSelected(tester, 'NYJ'), isFalse);
    expect(
      find.descendant(of: jetsStar, matching: find.byIcon(Icons.star)),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('game-NYJ-TEN'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('game-ARI-LAC'))).dy),
    );

    await tapTeam(tester, 'NE');
    expect(
      tester.getTopLeft(find.byKey(const Key('game-NE-SEA'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('game-NYJ-TEN'))).dy),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openSheet(
      tester,
      store: SharedPreferencesPickStore(),
      favorites: SharedPreferencesFavoriteStore(),
    );
    final starred = find.byKey(const Key('favorite-NYJ'));
    await tester.scrollUntilVisible(starred, 400);
    expect(
      find.descendant(of: starred, matching: find.byIcon(Icons.star)),
      findsOneWidget,
    );

    await tester.tap(starred);
    await tester.pumpAndSettle();
    final hollow = find.byKey(const Key('favorite-NYJ'));
    await tester.scrollUntilVisible(hollow, 400);
    expect(
      find.descendant(of: hollow, matching: find.byIcon(Icons.star_border)),
      findsOneWidget,
    );
  });

  testWidgets('tapping a selected team clears only that week', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await openSheet(tester, store: SharedPreferencesPickStore());

    await tapTeam(tester, 'SEA');
    expect(find.text('Enter the team you picked for Week 1'), findsNothing);
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

    await tester.tap(find.byKey(const Key('next-week')));
    await tester.pumpAndSettle();
    final arizona = find.byKey(const Key('team-ARI'));
    await tester.scrollUntilVisible(arizona, 400);
    await tester.tap(arizona);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('team-ARI')),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );

    await jumpTo(tester, 1);
    await tapTeam(tester, 'SEA');
    expect(find.byIcon(Icons.check), findsNothing);
    expect(teamIsSelected(tester, 'SEA'), isFalse);

    await jumpTo(tester, 2);
    await tester.scrollUntilVisible(find.byKey(const Key('team-ARI')), 400);
    expect(
      find.descendant(
        of: find.byKey(const Key('team-ARI')),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openSheet(tester, store: SharedPreferencesPickStore());
    expect(find.byIcon(Icons.check), findsNothing);
    expect(teamIsSelected(tester, 'SEA'), isFalse);

    await jumpTo(tester, 2);
    await tester.scrollUntilVisible(find.byKey(const Key('team-ARI')), 400);
    expect(
      find.descendant(
        of: find.byKey(const Key('team-ARI')),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );
  });
}

const String usedFooter =
    "A team you've already used can't be picked again. "
    'A game is hidden only when both teams are used.';
