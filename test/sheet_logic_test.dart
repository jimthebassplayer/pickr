import 'package:flutter_test/flutter_test.dart';
import 'package:pickr/data/game.dart';
import 'package:pickr/data/schedule.dart';
import 'package:pickr/data/season.dart';
import 'package:pickr/data/teams.dart';
import 'package:pickr/logic/sheet.dart';
import 'package:pickr/persistence/favorite_store.dart';
import 'package:pickr/persistence/pick_store.dart';

void main() {
  test('schedule covers the posted 2026 slate', () {
    expect(teamNicknames, hasLength(32));
    expect(currentWeek, 5);
    expect(seasonWeeks, 18);

    for (var week = 1; week <= 4; week++) {
      final games = gamesForWeek(week);
      expect(games, hasLength(16), reason: 'week $week');
      final teams = [
        for (final game in games) ...[game.away, game.home],
      ];
      expect(teams.toSet(), hasLength(32), reason: 'week $week');
      expect(games.every((game) => game.isFinal), isTrue, reason: 'week $week');
    }

    final week5 = gamesForWeek(5);
    expect(week5, hasLength(15));
    final week5Teams = [
      for (final game in week5) ...[game.away, game.home],
    ];
    expect(week5Teams.toSet(), hasLength(30));
    expect(week5.every((game) => !game.isFinal), isTrue);

    const futureCounts = {
      6: 14,
      7: 14,
      8: 14,
      9: 15,
      10: 14,
      11: 13,
      12: 16,
      13: 14,
      14: 15,
      15: 16,
      16: 16,
      17: 16,
      18: 16,
    };
    for (final entry in futureCounts.entries) {
      final games = gamesForWeek(entry.key);
      expect(games, hasLength(entry.value), reason: 'week ${entry.key}');
      expect(games.every((game) => !game.isFinal), isTrue);
      final teams = [
        for (final game in games) ...[game.away, game.home],
      ];
      expect(
        teams.toSet(),
        hasLength(teams.length),
        reason: 'week ${entry.key}',
      );
      final lined = entry.key == 6;
      expect(
        games.every((game) => (game.spread != null) == lined),
        isTrue,
        reason: 'week ${entry.key} spreads',
      );
    }
    final seaAtDenver = gamesForWeek(
      6,
    ).singleWhere((game) => game.away == 'SEA' && game.home == 'DEN');
    expect(formatSpread(seaAtDenver.spread), '-1.5');

    for (final game in schedule) {
      expect(teamNicknames.containsKey(game.away), isTrue, reason: game.away);
      expect(teamNicknames.containsKey(game.home), isTrue, reason: game.home);
      expect(game.away == game.home, isFalse);
      final scoresSet = game.awayScore != null && game.homeScore != null;
      final scoresBlank = game.awayScore == null && game.homeScore == null;
      expect(scoresSet || scoresBlank, isTrue);
      if (scoresSet) {
        expect(game.awayScore == game.homeScore, isFalse);
      }
    }

    expect(
      schedule
          .where((game) => game.note != null)
          .map((game) => '${game.week} ${game.note}'),
      [
        '1 Melbourne',
        '3 Brazil',
        '4 London',
        '5 London',
        '6 London',
        '7 France',
        '9 Spain',
        '10 Germany',
      ],
    );
  });

  test('records entering week 5 include week 4 and the away spread', () {
    final seahawks = snapshotEnteringWeek('SEA', 5);
    expect(seahawks.record, '(3-1)');
    expect(seahawks.recent.map((line) => line.label), [
      'W 30-23 at home',
      'L 31-33 at Commanders',
    ]);

    final niners = snapshotEnteringWeek('SF', 5);
    expect(niners.record, '(4-0)');
    expect(niners.recent.map((line) => line.label), [
      'W 24-14 at home',
      'W 36-30 at home',
    ]);

    final slate = gamesForWeek(
      5,
    ).singleWhere((game) => game.away == 'SF' && game.home == 'SEA');
    expect(formatSpread(slate.spread), '+3');
    expect(snapshotEnteringWeek('SEA', 1).record, '(0-0)');
    expect(snapshotEnteringWeek('SEA', 1).recent, isEmpty);
  });

  test('spread formatting', () {
    expect(formatSpread(null), isEmpty);
    expect(formatSpread(0), 'PK');
    expect(formatSpread(-7), '-7');
    expect(formatSpread(3), '+3');
    expect(formatSpread(-6.5), '-6.5');
    expect(formatSpread(3.5), '+3.5');
  });

  test('card status keeps the site note', () {
    final melbourne = schedule.firstWhere((game) => game.note == 'Melbourne');
    expect(cardStatus(melbourne), 'FINAL · Melbourne');
    final london = schedule.firstWhere(
      (game) => game.week == 5 && game.note == 'London',
    );
    expect(cardStatus(london), 'London');
    final plain = schedule.firstWhere(
      (game) => game.week == 1 && game.away == 'NE',
    );
    expect(cardStatus(plain), 'FINAL');
  });

  test('a used team stays visible until both teams are used', () {
    final picks = {1: 'SEA'};
    final week2 = visibleGames(2, picks);
    expect(
      week2.any((game) => game.away == 'SEA' && game.home == 'ARI'),
      isTrue,
    );
    final seaAtArizona = week2.singleWhere(
      (game) => game.away == 'SEA' && game.home == 'ARI',
    );
    expect(teamIsUsed('SEA', 2, picks), isTrue);
    expect(teamIsUsed('ARI', 2, picks), isFalse);
    expect(canPickTeam(seaAtArizona, 'SEA', picks), isFalse);
    expect(canPickTeam(seaAtArizona, 'ARI', picks), isTrue);

    expect(visibleGames(1, {1: 'SEA'}), hasLength(16));
    expect(showUsedFooter(1, {1: 'SEA'}), isFalse);
    expect(showUsedFooter(2, picks), isTrue);

    final both = {1: 'ATL', 2: 'GB'};
    expect(
      visibleGames(
        3,
        both,
      ).any((game) => game.away == 'ATL' && game.home == 'GB'),
      isFalse,
    );
    expect(everyRemainingGameHidden(3, both), isFalse);
    expect(visibleGames(3, both), isNotEmpty);
  });

  test('changing a pick drops a later pick of that team only', () {
    final replaced = picksAfterSelecting(
      picks: {1: 'SEA', 2: 'ARI', 3: 'GB'},
      week: 1,
      team: 'ARI',
    );
    expect(replaced, {1: 'ARI', 3: 'GB'});

    final opponentStays = picksAfterSelecting(
      picks: {1: 'NE', 2: 'ARI'},
      week: 1,
      team: 'SEA',
    );
    expect(opponentStays, {1: 'SEA', 2: 'ARI'});

    expect(picksAfterClearingWeek({1: 'SEA', 2: 'ARI', 3: 'GB'}, 1), {
      2: 'ARI',
      3: 'GB',
    });
    expect(picksAfterClearingWeek({1: 'SEA'}, 1), isEmpty);
  });

  test('week copy, locks, and navigation', () {
    expect(weekInstruction(1, {}), 'Enter the team you picked for Week 1');
    expect(weekInstruction(1, {1: 'SEA'}), isEmpty);
    expect(weekInstruction(2, {}), "You haven't picked for Week 1 yet.");
    expect(
      weekInstruction(2, {1: 'SEA'}),
      'Enter the team you picked for Week 2',
    );
    expect(weekInstruction(2, {1: 'SEA', 2: 'ARI'}), isEmpty);
    expect(
      weekInstruction(5, {}),
      'Week 5 stays closed until Weeks 1–4 are filled in.',
    );
    expect(weekInstruction(5, {1: 'NE', 2: 'GB', 3: 'KC', 4: 'DAL'}), isEmpty);
    expect(weekAcceptsPicks(1, {}), isTrue);
    expect(weekAcceptsPicks(2, {}), isFalse);
    expect(weekAcceptsPicks(2, {1: 'SEA'}), isTrue);
    expect(weekAcceptsPicks(4, {1: 'NE', 3: 'KC'}), isFalse);
    expect(weekAcceptsPicks(5, {}), isFalse);
    expect(weekAcceptsPicks(5, {1: 'NE', 2: 'GB', 3: 'KC', 4: 'DAL'}), isTrue);
    expect(weekAcceptsPicks(6, {1: 'NE', 2: 'GB', 3: 'KC', 4: 'DAL'}), isFalse);
    expect(
      weekAcceptsPicks(6, {1: 'NE', 2: 'GB', 3: 'KC', 4: 'DAL', 5: 'SEA'}),
      isFalse,
    );

    expect(
      futureWeekInstruction(6, posted: false),
      "Matchups and spreads for Week 6 aren't posted yet. "
      "You can look ahead, but there's nothing to pick.",
    );
    expect(
      futureWeekInstruction(6, posted: true),
      'Week 6 — look only, not open for picks.',
    );
    expect(
      weekInstruction(6, {}),
      "You haven't picked for Week 1, Week 2, Week 3, Week 4, Week 5 yet.",
    );
    expect(
      weekInstruction(6, {1: 'NE', 2: 'GB', 3: 'KC', 4: 'DAL', 5: 'SEA'}),
      'Week 6 — look only, not open for picks.',
    );

    expect(selectBlockedMessage(1, {}), isNull);
    expect(selectBlockedMessage(2, {}), "You haven't picked for Week 1 yet.");
    expect(
      selectBlockedMessage(6, {}),
      "You haven't picked for Week 1, Week 2, Week 3, Week 4, Week 5 yet.",
    );
    expect(
      selectBlockedMessage(5, {1: 'NE', 3: 'KC'}),
      "You haven't picked for Week 2, Week 4 yet.",
    );
    expect(
      selectBlockedMessage(6, {1: 'NE', 3: 'KC', 4: 'DAL'}),
      "You haven't picked for Week 2, Week 5 yet.",
    );
    final caughtUpPicks = {1: 'NE', 2: 'GB', 3: 'KC', 4: 'DAL'};
    final throughFive = {...caughtUpPicks, 5: 'SEA'};
    expect(
      selectBlockedMessage(8, throughFive),
      "You haven't picked for Week 6, Week 7 yet.",
    );
    expect(
      selectBlockedMessage(6, throughFive),
      'Week 6 — look only, not open for picks.',
    );
    expect(selectBlockedMessage(5, caughtUpPicks), isNull);

    expect(stillOpenLine({}), 'Still open: Week 1, Week 2, Week 3, Week 4');
    expect(stillOpenLine({1: 'NE', 3: 'KC'}), 'Still open: Week 2, Week 4');
    expect(stillOpenLine({1: 'NE', 2: 'GB', 3: 'KC', 4: 'DAL'}), isEmpty);

    expect(weekMenuLabel(5, {}), 'Week 5 · this week');
    expect(weekMenuLabel(2, {}), 'Week 2 · needs a pick');
    expect(weekMenuLabel(2, {2: 'GB'}), 'Week 2');
    expect(weekMenuLabel(12, {}), 'Week 12');

    final openFinal = Game(
      week: 5,
      away: 'TB',
      home: 'DAL',
      spread: 9.5,
      awayScore: 10,
      homeScore: 20,
    );
    final caughtUp = {1: 'NE', 2: 'GB', 3: 'KC', 4: 'DAL'};
    expect(gameAcceptsPicks(openFinal, caughtUp), isFalse);
    expect(cardIsDimmed(openFinal, caughtUp), isTrue);
    expect(cardIsDimmed(gamesForWeek(5).first, {}), isTrue);
    expect(cardIsDimmed(gamesForWeek(5).first, caughtUp), isFalse);
    expect(cardIsDimmed(gamesForWeek(2).first, {}), isFalse);
    expect(cardIsDimmed(gamesForWeek(6).first, {}), isFalse);
    expect(cardIsDimmed(gamesForWeek(12).first, caughtUp), isFalse);
    expect(
      gameAcceptsPicks(
        const Game(week: 5, away: 'TB', home: 'DAL', spread: 9.5),
        caughtUp,
      ),
      isTrue,
    );

    final week1 = gamesForWeek(1).first;
    expect(gameAcceptsPicks(week1, {}), isTrue);
    expect(pickWon(week1, 'SEA'), isTrue);
    expect(pickWon(week1, 'NE'), isFalse);
    expect(pickWon(week1, null), isNull);

    expect(dotTone(week: 3, onScreen: 3, picks: {}), DotTone.accent);
    expect(dotTone(week: 1, onScreen: 3, picks: {1: 'SEA'}), DotTone.light);
    expect(dotTone(week: 2, onScreen: 3, picks: {1: 'SEA'}), DotTone.dim);
    expect(dotTone(week: 5, onScreen: 1, picks: {}), DotTone.dim);
  });

  test('matchups sort by pick, then favorites, then spread', () {
    final games = [
      const Game(week: 9, away: 'DAL', home: 'IND', spread: 3),
      const Game(week: 9, away: 'BUF', home: 'MIN', spread: -10),
      const Game(week: 9, away: 'ARI', home: 'SEA', spread: 10),
      const Game(week: 9, away: 'CLE', home: 'NO'),
      const Game(week: 9, away: 'NYJ', home: 'KC'),
    ];

    expect(
      orderedGames(games, pick: null, favorites: {}).map((game) => game.away),
      ['BUF', 'ARI', 'DAL', 'CLE', 'NYJ'],
    );
    expect(
      orderedGames(
        games,
        pick: null,
        favorites: {'NYJ'},
      ).map((game) => game.away),
      ['NYJ', 'BUF', 'ARI', 'DAL', 'CLE'],
    );
    expect(
      orderedGames(
        games,
        pick: 'DAL',
        favorites: {'NYJ'},
      ).map((game) => game.away),
      ['DAL', 'NYJ', 'BUF', 'ARI', 'CLE'],
    );

    final week1 = orderedGames(gamesForWeek(1), pick: null, favorites: {});
    expect(week1.first.away, 'ARI');
    expect(week1.first.home, 'LAC');
    expect(week1[1].away, 'CLE');

    final week7 = orderedGames(gamesForWeek(7), pick: null, favorites: {});
    expect(week7.first.away, 'SF');
    expect(
      orderedGames(gamesForWeek(7), pick: null, favorites: {'DEN'}).first.away,
      'DEN',
    );
  });

  test('favorites round-trip through storage encoding', () {
    expect(encodeFavorites({'SEA', 'GB'}), '["GB","SEA"]');
    expect(decodeFavorites('["SEA","NOPE"]'), {'SEA'});
    expect(decodeFavorites(null), isEmpty);
    expect(decodeFavorites('nope'), isEmpty);
  });

  test('picks round-trip through storage encoding', () {
    final encoded = encodePicks({1: 'SEA', 4: 'DAL'});
    expect(decodePicks(encoded), {1: 'SEA', 4: 'DAL'});
    expect(decodePicks(null), isEmpty);
    expect(decodePicks('not json'), isEmpty);
    expect(decodePicks('{"1":"NOPE","9":"SEA","0":"GB"}'), {9: 'SEA'});
  });
}
