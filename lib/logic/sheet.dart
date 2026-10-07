import '../data/game.dart';
import '../data/schedule.dart';
import '../data/season.dart';
import '../data/teams.dart';

enum WeekPhase { past, current, future }

class TeamResultLine {
  const TeamResultLine({
    required this.won,
    required this.teamScore,
    required this.opponentScore,
    required this.place,
  });

  final bool won;
  final int teamScore;
  final int opponentScore;

  /// "home", or the nickname of the stadium's team.
  final String place;

  String get label {
    final mark = won ? 'W' : 'L';
    return '$mark $teamScore-$opponentScore at $place';
  }
}

class TeamSnapshot {
  const TeamSnapshot({
    required this.wins,
    required this.losses,
    required this.recent,
  });

  final int wins;
  final int losses;

  /// Most recent game first. At most two.
  final List<TeamResultLine> recent;

  String get record => '($wins-$losses)';
}

WeekPhase weekPhase(int week) {
  if (week < currentWeek) return WeekPhase.past;
  if (week == currentWeek) return WeekPhase.current;
  return WeekPhase.future;
}

List<Game> gamesForWeek(int week) {
  return [
    for (final game in schedule)
      if (game.week == week) game,
  ];
}

/// Record and last two finals from weeks strictly before [week].
TeamSnapshot snapshotEnteringWeek(String code, int week) {
  final played =
      <({int week, bool atHome, String home, int teamScore, int oppScore})>[];
  for (final game in schedule) {
    if (game.week >= week || !game.isFinal) continue;
    final atHome = game.home == code;
    if (!atHome && game.away != code) continue;
    final teamScore = atHome ? game.homeScore! : game.awayScore!;
    final oppScore = atHome ? game.awayScore! : game.homeScore!;
    if (teamScore == oppScore) continue;
    played.add((
      week: game.week,
      atHome: atHome,
      home: game.home,
      teamScore: teamScore,
      oppScore: oppScore,
    ));
  }
  played.sort((a, b) => b.week.compareTo(a.week));

  var wins = 0;
  var losses = 0;
  for (final game in played) {
    if (game.teamScore > game.oppScore) {
      wins++;
    } else {
      losses++;
    }
  }

  final recent = [
    for (final game in played.take(2))
      TeamResultLine(
        won: game.teamScore > game.oppScore,
        teamScore: game.teamScore,
        opponentScore: game.oppScore,
        place: game.atHome ? 'home' : nicknameOf(game.home),
      ),
  ];
  return TeamSnapshot(wins: wins, losses: losses, recent: recent);
}

Set<String> teamsUsedBefore(int week, Map<int, String> picks) {
  return {
    for (final entry in picks.entries)
      if (entry.key < week) entry.value,
  };
}

/// A game is hidden only when both of its teams were picked in an earlier week.
List<Game> visibleGames(int week, Map<int, String> picks) {
  final used = teamsUsedBefore(week, picks);
  return [
    for (final game in gamesForWeek(week))
      if (!used.contains(game.away) || !used.contains(game.home)) game,
  ];
}

bool teamIsUsed(String code, int week, Map<int, String> picks) {
  return teamsUsedBefore(week, picks).contains(code);
}

List<int> weeksStillOpen(Map<int, String> picks) {
  return [
    for (var week = 1; week < currentWeek; week++)
      if (!picks.containsKey(week)) week,
  ];
}

bool isCaughtUp(Map<int, String> picks) => weeksStillOpen(picks).isEmpty;

/// Weeks before [week] that still have no pick.
List<int> weeksMissingBefore(int week, Map<int, String> picks) {
  return [
    for (var earlier = 1; earlier < week; earlier++)
      if (!picks.containsKey(earlier)) earlier,
  ];
}

/// Past and current weeks open only after every earlier week has a pick.
/// Future weeks stay look-only.
bool weekAcceptsPicks(int week, Map<int, String> picks) {
  if (weekPhase(week) == WeekPhase.future) return false;
  return weeksMissingBefore(week, picks).isEmpty;
}

/// A final game in the open week stays locked. Past finals stay editable.
bool gameAcceptsPicks(Game game, Map<int, String> picks) {
  if (!weekAcceptsPicks(game.week, picks)) return false;
  if (weekPhase(game.week) == WeekPhase.current && game.isFinal) return false;
  return true;
}

bool canPickTeam(Game game, String code, Map<int, String> picks) {
  if (code != game.away && code != game.home) return false;
  if (!gameAcceptsPicks(game, picks)) return false;
  if (teamIsUsed(code, game.week, picks)) return false;
  return true;
}

/// Only a closed current week, or a final game in the open week, is dimmed.
/// Earlier and future weeks stay readable so the slate can be looked through.
bool cardIsDimmed(Game game, Map<int, String> picks) {
  if (weekPhase(game.week) != WeekPhase.current) return false;
  return !gameAcceptsPicks(game, picks);
}

/// Why a tap on [week] cannot be saved, or null when the week is open.
String? selectBlockedMessage(int week, Map<int, String> picks) {
  final missing = weeksMissingBefore(week, picks);
  if (missing.isNotEmpty) {
    final list = missing.map((openWeek) => 'Week $openWeek').join(', ');
    return "You haven't picked for $list yet.";
  }
  if (weekPhase(week) == WeekPhase.future) {
    return 'Week $week — look only, not open for picks.';
  }
  return null;
}

/// An existing pick can be cleared on a past or current week, even if an
/// earlier week was cleared later. A final game in the open week stays locked.
bool canClearPick(Game game, String code, Map<int, String> picks) {
  if (picks[game.week] != code) return false;
  if (weekPhase(game.week) == WeekPhase.future) return false;
  if (weekPhase(game.week) == WeekPhase.current && game.isFinal) return false;
  return true;
}

/// Picking [team] in [week] replaces that week and drops any later pick of the
/// same team. A later pick of the opponent stays.
Map<int, String> picksAfterSelecting({
  required Map<int, String> picks,
  required int week,
  required String team,
}) {
  final next = Map<int, String>.from(picks);
  next[week] = team;
  next.removeWhere((laterWeek, picked) => laterWeek > week && picked == team);
  return next;
}

/// Drop just this week's pick. Later picks stay.
Map<int, String> picksAfterClearingWeek(Map<int, String> picks, int week) {
  final next = Map<int, String>.from(picks);
  next.remove(week);
  return next;
}

/// Selected game, then games with a favorite, then the biggest absolute
/// spread. Games without a line fall back to the away nickname.
List<Game> orderedGames(
  List<Game> games, {
  required String? pick,
  required Set<String> favorites,
}) {
  final sorted = [...games];
  sorted.sort((a, b) {
    final byRank = _orderRank(
      a,
      pick,
      favorites,
    ).compareTo(_orderRank(b, pick, favorites));
    if (byRank != 0) return byRank;
    return _compareSpreadThenAway(a, b);
  });
  return sorted;
}

int _orderRank(Game game, String? pick, Set<String> favorites) {
  if (pick != null && (game.away == pick || game.home == pick)) return 0;
  if (favorites.contains(game.away) || favorites.contains(game.home)) {
    return 1;
  }
  return 2;
}

int _compareSpreadThenAway(Game a, Game b) {
  final aSpread = a.spread;
  final bSpread = b.spread;
  if (aSpread != null && bSpread != null) {
    final bySpread = bSpread.abs().compareTo(aSpread.abs());
    if (bySpread != 0) return bySpread;
  } else if (aSpread != null) {
    return -1;
  } else if (bSpread != null) {
    return 1;
  }
  return nicknameOf(a.away).compareTo(nicknameOf(b.away));
}

String weekInstruction(int week, Map<int, String> picks) {
  switch (weekPhase(week)) {
    case WeekPhase.past:
      if (picks.containsKey(week)) return '';
      final blocked = selectBlockedMessage(week, picks);
      if (blocked != null) return blocked;
      return 'Enter the team you picked for Week $week';
    case WeekPhase.current:
      if (isCaughtUp(picks)) return '';
      final through = currentWeek - 1;
      return 'Week $currentWeek stays closed until Weeks 1–$through are filled in.';
    case WeekPhase.future:
      if (gamesForWeek(week).isEmpty) {
        return futureWeekInstruction(week, posted: false);
      }
      return selectBlockedMessage(week, picks)!;
  }
}

String futureWeekInstruction(int week, {required bool posted}) {
  if (!posted) {
    return "Matchups and spreads for Week $week aren't posted yet. "
        "You can look ahead, but there's nothing to pick.";
  }
  return 'Week $week — look only, not open for picks.';
}

String stillOpenLine(Map<int, String> picks) {
  final weeks = weeksStillOpen(picks);
  if (weeks.isEmpty) return '';
  return 'Still open: ${weeks.map((week) => 'Week $week').join(', ')}';
}

const String bothUsedMessage =
    'Both teams in every remaining game have already been used.';

const String usedFooter =
    "A team you've already used can't be picked again. "
    'A game is hidden only when both teams are used.';

bool showUsedFooter(int week, Map<int, String> picks) {
  return teamsUsedBefore(week, picks).isNotEmpty;
}

bool everyRemainingGameHidden(int week, Map<int, String> picks) {
  final games = gamesForWeek(week);
  return games.isNotEmpty && visibleGames(week, picks).isEmpty;
}

/// No line is blank. Zero is PK. Every other number keeps its sign.
String formatSpread(double? spread) {
  if (spread == null) return '';
  if (spread == 0) return 'PK';
  final digits = spread == spread.roundToDouble()
      ? spread.abs().toInt().toString()
      : spread.abs().toString();
  return spread > 0 ? '+$digits' : '-$digits';
}

String? cardStatus(Game game) {
  if (game.isFinal && game.note != null) return 'FINAL · ${game.note}';
  if (game.isFinal) return 'FINAL';
  if (game.note != null) return game.note;
  return null;
}

/// True if [pick] won, false if it lost, null if the game is not final,
/// the pick is not in the game, or the score is tied.
bool? pickWon(Game game, String? pick) {
  if (pick == null || !game.isFinal) return null;
  if (pick != game.away && pick != game.home) return null;
  final teamScore = pick == game.home ? game.homeScore! : game.awayScore!;
  final oppScore = pick == game.home ? game.awayScore! : game.homeScore!;
  if (teamScore == oppScore) return null;
  return teamScore > oppScore;
}

String weekMenuLabel(int week, Map<int, String> picks) {
  final marks = <String>[];
  if (week == currentWeek) marks.add('this week');
  if (weekPhase(week) == WeekPhase.past && !picks.containsKey(week)) {
    marks.add('needs a pick');
  }
  if (marks.isEmpty) return 'Week $week';
  return 'Week $week · ${marks.join(' · ')}';
}

DotTone dotTone({
  required int week,
  required int onScreen,
  required Map<int, String> picks,
}) {
  if (week == onScreen) return DotTone.accent;
  if (weekPhase(week) == WeekPhase.past && picks.containsKey(week)) {
    return DotTone.light;
  }
  return DotTone.dim;
}

enum DotTone { accent, light, dim }
