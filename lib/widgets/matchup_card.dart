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
    required this.favorites,
    required this.onPick,
    required this.onClearPick,
    required this.onBlockedTap,
    required this.onToggleFavorite,
    required this.onControlPointerDown,
  });

  final Game game;
  final Map<int, String> picks;
  final Set<String> favorites;
  final ValueChanged<String> onPick;
  final VoidCallback onClearPick;
  final VoidCallback onBlockedTap;
  final ValueChanged<String> onToggleFavorite;
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
                    favorites: favorites,
                    alignEnd: false,
                    onPick: onPick,
                    onClearPick: onClearPick,
                    onBlockedTap: onBlockedTap,
                    onToggleFavorite: onToggleFavorite,
                    onControlPointerDown: onControlPointerDown,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          formatSpread(game.spread),
                          textAlign: TextAlign.right,
                          style: displayStyle(
                            size: 22,
                            color: AppColors.accent,
                          ),
                        ),
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
                    favorites: favorites,
                    alignEnd: true,
                    onPick: onPick,
                    onClearPick: onClearPick,
                    onBlockedTap: onBlockedTap,
                    onToggleFavorite: onToggleFavorite,
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
    required this.favorites,
    required this.alignEnd,
    required this.onPick,
    required this.onClearPick,
    required this.onBlockedTap,
    required this.onToggleFavorite,
    required this.onControlPointerDown,
  });

  final String code;
  final Game game;
  final TeamSnapshot snapshot;
  final Map<int, String> picks;
  final Set<String> favorites;
  final bool alignEnd;
  final ValueChanged<String> onPick;
  final VoidCallback onClearPick;
  final VoidCallback onBlockedTap;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<int> onControlPointerDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TeamTile(
          code: code,
          game: game,
          snapshot: snapshot,
          picks: picks,
          favorite: favorites.contains(code),
          alignEnd: alignEnd,
          onPick: onPick,
          onClearPick: onClearPick,
          onBlockedTap: onBlockedTap,
          onToggleFavorite: onToggleFavorite,
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
    required this.favorite,
    required this.alignEnd,
    required this.onPick,
    required this.onClearPick,
    required this.onBlockedTap,
    required this.onToggleFavorite,
    required this.onControlPointerDown,
  });

  final String code;
  final Game game;
  final TeamSnapshot snapshot;
  final Map<int, String> picks;
  final bool favorite;
  final bool alignEnd;
  final ValueChanged<String> onPick;
  final VoidCallback onClearPick;
  final VoidCallback onBlockedTap;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<int> onControlPointerDown;

  /// A second tap on the selected team clears only this week. A tap that
  /// cannot be saved explains why. A used team on an open week stays quiet.
  VoidCallback? get _onTap {
    if (canClearPick(game, code, picks)) return onClearPick;
    if (canPickTeam(game, code, picks)) return () => onPick(code);
    if (selectBlockedMessage(game.week, picks) != null) return onBlockedTap;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = picks[game.week] == code;
    final used = teamIsUsed(code, game.week, picks);
    final won = selected ? pickWon(game, code) : null;
    final foreground = selected ? AppColors.onAccent : AppColors.text;
    final secondary = selected
        ? AppColors.onAccent.withValues(alpha: 0.72)
        : AppColors.muted;

    final starColor = favorite
        ? AppColors.star
        : (selected ? AppColors.onAccent : AppColors.muted);

    return Listener(
      onPointerDown: (event) => onControlPointerDown(event.pointer),
      child: Stack(
        children: [
          Material(
            color: selected ? AppColors.accent : AppColors.team,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              key: Key('team-$code'),
              onTap: _onTap,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 36, 8),
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
                                style: displayStyle(
                                  size: 18,
                                  color: foreground,
                                ),
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
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              key: Key('favorite-$code'),
              onPressed: () => onToggleFavorite(code),
              icon: Icon(favorite ? Icons.star : Icons.star_border),
              color: starColor,
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ),
        ],
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
