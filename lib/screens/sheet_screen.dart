import 'package:flutter/material.dart';

import '../data/season.dart';
import '../logic/sheet.dart';
import '../persistence/favorite_store.dart';
import '../persistence/pick_store.dart';
import '../theme/app_theme.dart';
import '../widgets/matchup_card.dart';

class SheetScreen extends StatefulWidget {
  const SheetScreen({super.key, required this.store, required this.favorites});

  final PickStore store;
  final FavoriteStore favorites;

  @override
  State<SheetScreen> createState() => _SheetScreenState();
}

class _SheetScreenState extends State<SheetScreen> {
  final GlobalKey _weekMenuKey = GlobalKey();
  final Map<int, Offset> _pointerOrigin = {};
  final Set<int> _controlPointers = {};

  Map<int, String> _picks = {};
  Set<String> _favorites = {};
  int _week = 1;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final picks = await widget.store.load();
    final favorites = await widget.favorites.load();
    if (!mounted) return;
    setState(() {
      _picks = picks;
      _favorites = favorites;
      _ready = true;
    });
  }

  Future<void> _save(Map<int, String> picks) {
    return widget.store.save(picks);
  }

  void _markControl(int pointer) {
    _controlPointers.add(pointer);
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerOrigin[event.pointer] = event.position;
  }

  void _onPointerUp(PointerUpEvent event) {
    final origin = _pointerOrigin.remove(event.pointer);
    final fromControl = _controlPointers.remove(event.pointer);
    if (!_ready || origin == null || fromControl) return;
    final delta = event.position - origin;
    if (delta.dx.abs() < 72 || delta.dx.abs() < delta.dy.abs() * 1.5) return;
    if (delta.dx < 0) {
      _goTo(_week + 1);
    } else {
      _goTo(_week - 1);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerOrigin.remove(event.pointer);
    _controlPointers.remove(event.pointer);
  }

  void _goTo(int week) {
    if (week < 1 || week > seasonWeeks || week == _week) return;
    setState(() => _week = week);
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSelectBlocked() {
    final message = selectBlockedMessage(_week, _picks);
    if (message == null) return;
    _showMessage(message);
  }

  Future<void> _pick(String code) async {
    final next = picksAfterSelecting(picks: _picks, week: _week, team: code);
    setState(() => _picks = next);
    await _save(next);
  }

  Future<void> _clearWeek() async {
    final next = picksAfterClearingWeek(_picks, _week);
    setState(() => _picks = next);
    await _save(next);
  }

  Future<void> _toggleFavorite(String code) async {
    final next = Set<String>.of(_favorites);
    if (!next.add(code)) next.remove(code);
    setState(() => _favorites = next);
    await widget.favorites.save(next);
  }

  Future<void> _openWeekMenu() async {
    final button =
        _weekMenuKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;
    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final selected = await showMenu<int>(
      context: context,
      color: AppColors.surface,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      items: [
        for (var week = 1; week <= seasonWeeks; week++)
          PopupMenuItem<int>(
            key: Key('jump-$week'),
            value: week,
            height: 48,
            child: Text(
              weekMenuLabel(week, _picks),
              style: TextStyle(
                fontFamily: kBodyFont,
                fontSize: 16,
                fontWeight: week == _week ? FontWeight.w600 : FontWeight.w400,
                color: week == currentWeek ? AppColors.accent : AppColors.text,
              ),
            ),
          ),
      ],
    );
    if (!mounted || selected == null) return;
    _goTo(selected);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SizedBox.expand(),
      );
    }

    final instruction = weekInstruction(_week, _picks);
    final stillOpen = stillOpenLine(_picks);
    final games = orderedGames(
      visibleGames(_week, _picks),
      pick: _picks[_week],
      favorites: _favorites,
    );
    final hidden = everyRemainingGameHidden(_week, _picks);
    final footer = showUsedFooter(_week, _picks);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: SafeArea(
          child: Padding(
            key: const Key('sheet'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('SURVIVOR', style: labelStyle(size: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _WeekArrow(
                      key: const Key('prev-week'),
                      icon: Icons.chevron_left,
                      enabled: _week > 1,
                      onPointerDown: _markControl,
                      onPressed: () => _goTo(_week - 1),
                    ),
                    Expanded(
                      child: Listener(
                        onPointerDown: (event) => _markControl(event.pointer),
                        child: Material(
                          key: _weekMenuKey,
                          color: Colors.transparent,
                          child: InkWell(
                            key: const Key('week-menu'),
                            onTap: _openWeekMenu,
                            borderRadius: BorderRadius.circular(10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Week $_week',
                                        key: const Key('week-title'),
                                        style: displayStyle(
                                          size: 42,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.expand_more,
                                        color: AppColors.muted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _WeekArrow(
                      key: const Key('next-week'),
                      icon: Icons.chevron_right,
                      enabled: _week < seasonWeeks,
                      onPointerDown: _markControl,
                      onPressed: () => _goTo(_week + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _WeekDots(week: _week, picks: _picks),
                const SizedBox(height: 14),
                if (instruction.isNotEmpty)
                  Text(
                    instruction,
                    key: const Key('week-instruction'),
                    style: const TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 16,
                      height: 1.35,
                      color: AppColors.text,
                    ),
                  ),
                if (stillOpen.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    stillOpen,
                    key: const Key('still-open'),
                    style: const TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: games.isEmpty
                      ? const SizedBox.expand()
                      : hidden
                      ? Text(
                          bothUsedMessage,
                          key: const Key('both-used'),
                          style: const TextStyle(
                            fontFamily: kBodyFont,
                            fontSize: 16,
                            height: 1.35,
                            color: AppColors.text,
                          ),
                        )
                      : KeyedSubtree(
                          key: ValueKey(
                            '$_week|${_picks[_week]}|${(_favorites.toList()..sort()).join(',')}',
                          ),
                          child: ListView.separated(
                            key: const Key('matchup-list'),
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: games.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final game = games[index];
                              return MatchupCard(
                                game: game,
                                picks: _picks,
                                favorites: _favorites,
                                onPick: _pick,
                                onClearPick: _clearWeek,
                                onBlockedTap: _showSelectBlocked,
                                onToggleFavorite: _toggleFavorite,
                                onControlPointerDown: _markControl,
                              );
                            },
                          ),
                        ),
                ),
                if (footer)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: Text(
                      usedFooter,
                      key: const Key('used-footer'),
                      style: const TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onPointerDown,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final ValueChanged<int> onPointerDown;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => onPointerDown(event.pointer),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        color: AppColors.text,
        disabledColor: AppColors.muted.withValues(alpha: 0.35),
        iconSize: 28,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      ),
    );
  }
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.week, required this.picks});

  final int week;
  final Map<int, String> picks;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 1; index <= seasonWeeks; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: Container(
              key: Key('dot-$index'),
              width: index == week ? 8 : 6,
              height: index == week ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: switch (dotTone(
                  week: index,
                  onScreen: week,
                  picks: picks,
                )) {
                  DotTone.accent => AppColors.accent,
                  DotTone.light => AppColors.text,
                  DotTone.dim => AppColors.muted.withValues(alpha: 0.4),
                },
              ),
            ),
          ),
      ],
    );
  }
}
