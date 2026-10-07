import 'package:flutter/material.dart';

import '../data/game.dart';
import '../data/teams.dart';
import '../logic/sheet.dart';
import '../theme/app_theme.dart';

class MatchupCard extends StatelessWidget {
  const MatchupCard({
    super.key,
    required this.game,
    required this.picks,
    required this.onPick,
    required this.onControlPointerDown,
  });

  final Game game;
  final Map<int, String> picks;
  final ValueChanged<String> onPick;
  final ValueChanged<int> onControlPointerDown;

  @override
  Widget build(BuildContext context) {
    final away = snapshotEnteringWeek(game.away, game.week);
    final home = snapshotEnteringWeek(game.home, game.week);
    final dimmed = cardIsDimmed(game, picks);
    final status = cardStatus(game);
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        key: Key('game-${game.away}-${game.home}'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TeamSide(
                    code: game.away,
                    game: game,
                    snapshot: away,
                    picks: picks,
                    alignEnd: false,
                    onPick: onPick,
                    onControlPointerDown: onControlPointerDown,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatSpread(game.spread),
                        style: displayStyle(size: 22, color: AppColors.accent),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'at',
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _TeamSide(
                    code: game.home,
                    game: game,
                    snapshot: home,
                    picks: picks,
                    alignEnd: true,
                    onPick: onPick,
                    onControlPointerDown: onControlPointerDown,
                  ),
                ),
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: 8),
              Text(status, style: labelStyle(size: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.code,
    required this.game,
    required this.snapshot,
    required this.picks,
    required this.alignEnd,
    required this.onPick,
    required this.onControlPointerDown,
  });

  final String code;
  final Game game;
  final TeamSnapshot snapshot;
  final Map<int, String> picks;
  final bool alignEnd;
  final ValueChanged<String> onPick;
  final ValueChanged<int> onControlPointerDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        _TeamTile(
          code: code,
          game: game,
          snapshot: snapshot,
          picks: picks,
          alignEnd: alignEnd,
          onPick: onPick,
          onControlPointerDown: onControlPointerDown,
        ),
        for (final line in snapshot.recent)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _ResultText(
              line: line,
              align: alignEnd ? TextAlign.right : TextAlign.left,
            ),
          ),
      ],
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.code,
    required this.game,
    required this.snapshot,
    required this.picks,
    required this.alignEnd,
    required this.onPick,
    required this.onControlPointerDown,
  });

  final String code;
  final Game game;
  final TeamSnapshot snapshot;
  final Map<int, String> picks;
  final bool alignEnd;
  final ValueChanged<String> onPick;
  final ValueChanged<int> onControlPointerDown;

  @override
  Widget build(BuildContext context) {
    final selected = picks[game.week] == code;
    final used = teamIsUsed(code, game.week, picks);
    final tappable = canPickTeam(game, code, picks);
    final won = selected ? pickWon(game, code) : null;
    final foreground = selected ? AppColors.onAccent : AppColors.text;
    final secondary = selected
        ? AppColors.onAccent.withValues(alpha: 0.72)
        : AppColors.muted;

    return Listener(
      onPointerDown: (event) => onControlPointerDown(event.pointer),
      child: Material(
        color: selected ? AppColors.accent : AppColors.team,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: Key('team-$code'),
          onTap: tappable ? () => onPick(code) : null,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: alignEnd
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (alignEnd && won != null) _ResultMark(won: won),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: nicknameOf(code),
                            style: displayStyle(size: 18, color: foreground),
                            children: [
                              TextSpan(
                                text: ' ${snapshot.record}',
                                style: TextStyle(
                                  fontFamily: kBodyFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                          textAlign: alignEnd
                              ? TextAlign.right
                              : TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!alignEnd && won != null) _ResultMark(won: won),
                    ],
                  ),
                  if (used)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'USED',
                        style: labelStyle(size: 10, color: secondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultMark extends StatelessWidget {
  const _ResultMark({required this.won});

  final bool won;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: Icon(
          won ? Icons.check : Icons.close,
          key: Key(won ? 'mark-win' : 'mark-loss'),
          size: 18,
          color: won ? AppColors.win : AppColors.loss,
        ),
      ),
    );
  }
}

class _ResultText extends StatelessWidget {
  const _ResultText({required this.line, required this.align});

  final TeamResultLine? line;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    if (line == null) return const SizedBox.shrink();
    final mark = line!.won ? 'W' : 'L';
    final rest = ' ${line!.teamScore}-${line!.opponentScore} at ${line!.place}';
    return Text.rich(
      TextSpan(
        text: mark,
        style: TextStyle(
          fontFamily: kBodyFont,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: line!.won ? AppColors.win : AppColors.loss,
          height: 1.25,
        ),
        children: [
          TextSpan(
            text: rest,
            style: const TextStyle(
              fontFamily: kBodyFont,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
              height: 1.25,
            ),
          ),
        ],
      ),
      textAlign: align,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
