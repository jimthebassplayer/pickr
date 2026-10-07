class Game {
  const Game({
    required this.week,
    required this.away,
    required this.home,
    this.spread,
    this.awayScore,
    this.homeScore,
    this.note,
  });

  final int week;
  final String away;
  final String home;

  /// Spread from the away team's side. Negative means the away team is favored.
  /// Null means the line has not been posted.
  final double? spread;

  final int? awayScore;
  final int? homeScore;
  final String? note;

  bool get isFinal => awayScore != null && homeScore != null;
}
