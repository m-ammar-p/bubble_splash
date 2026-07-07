import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/leaderboard_controller.dart';
import '../../app/candy.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../widgets/player_avatar.dart';

/// Ranks: two-metric leaderboard (Top Score / Total Pops × Local / Global),
/// skinned to Candy Cosmos with the shared header/tab/card structure.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardScope _scope = LeaderboardScope.local;
  LeaderboardMetric _metric = LeaderboardMetric.highScore;

  @override
  Widget build(BuildContext context) {
    final entries =
        ref.watch(leaderboardProvider((scope: _scope, metric: _metric)));
    final s = candyScale(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CandyNebulaBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 0),
              child: Column(
                children: [
                  const _Header(),
                  SizedBox(height: 14 * s),
                  _CandyTabs<LeaderboardMetric>(
                    selected: _metric,
                    onChanged: (m) => setState(() => _metric = m),
                    tabs: const {
                      LeaderboardMetric.highScore:
                          (Icons.emoji_events, 'Top Score'),
                      LeaderboardMetric.totalPops:
                          (Icons.bubble_chart, 'Total Pops'),
                    },
                  ),
                  SizedBox(height: 8 * s),
                  _CandyTabs<LeaderboardScope>(
                    selected: _scope,
                    onChanged: (sc) => setState(() => _scope = sc),
                    tabs: const {
                      LeaderboardScope.local: (Icons.location_on, 'Local'),
                      LeaderboardScope.global: (Icons.public, 'Global'),
                    },
                  ),
                  SizedBox(height: 12 * s),
                  Expanded(
                    child: entries.when(
                      loading: () => const Center(
                        child:
                            CircularProgressIndicator(color: Candy.orange),
                      ),
                      error: (e, _) => Center(
                        child: Text('Could not load leaderboard\n$e',
                            textAlign: TextAlign.center,
                            style: Candy.ui(
                                size: 13 * s,
                                color:
                                    Colors.white.withValues(alpha: 0.55))),
                      ),
                      data: (list) => ListView.builder(
                        padding: EdgeInsets.only(bottom: 20 * s),
                        itemCount: list.length,
                        itemBuilder: (_, i) =>
                            _LeaderboardRow(entry: list[i], metric: _metric),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass back circle · centered "Ranks" title · width-matched spacer.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CandyBackCircle(),
        Text('Ranks', style: Candy.display(size: 20 * s)),
        SizedBox(width: kCandyBackCircleSize * s),
      ],
    );
  }
}

/// Glass segmented control: equal-width tabs in a pill track; the selected tab
/// gets the orange CTA gradient + ink text, unselected are translucent white.
class _CandyTabs<T> extends StatelessWidget {
  const _CandyTabs({
    required this.selected,
    required this.onChanged,
    required this.tabs,
  });

  final T selected;
  final ValueChanged<T> onChanged;

  /// Value → (icon, label), in display order.
  final Map<T, (IconData, String)> tabs;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    return CandyGlass(
      radius: 999,
      surfaceAlpha: 0.08,
      borderAlpha: 0.14,
      padding: EdgeInsets.all(3 * s),
      child: Row(
        children: [
          for (final MapEntry(key: value, value: (icon, label))
              in tabs.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  height: 34 * s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: value == selected
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Candy.orangeCtaTop,
                              Candy.orangeCtaBottom
                            ],
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          size: 15 * s,
                          color: value == selected
                              ? Candy.ctaInk
                              : Colors.white.withValues(alpha: 0.65)),
                      SizedBox(width: 6 * s),
                      Text(label,
                          style: Candy.ui(
                              size: 12.5 * s,
                              weight: FontWeight.w800,
                              color: value == selected
                                  ? Candy.ctaInk
                                  : Colors.white
                                      .withValues(alpha: 0.75))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rank row: rank number (gold Baloo for top 3), glossy bubble avatar, name +
/// level, metric value. The player's own row gets the amber "unlocked" tint
/// used by Profile achievements.
class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.metric});
  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final s = candyScale(context);
    final me = entry.isCurrentPlayer;
    return Container(
      margin: EdgeInsets.only(bottom: 8 * s),
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 9 * s),
      decoration: BoxDecoration(
        color: me
            ? const Color(0x1FFFC24D) // rgba(255,194,77,.12)
            : Candy.glass(0.08),
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(
          color: me
              ? const Color(0x80FFC24D) // rgba(255,194,77,.5)
              : Candy.glassBorder(0.14),
        ),
        boxShadow: me
            ? [
                BoxShadow(
                    color: Candy.orange.withValues(alpha: 0.15),
                    blurRadius: 16 * s),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30 * s,
            child: Text(
              '#${entry.rank}',
              style: Candy.display(
                size: 15 * s,
                height: 1,
                color: entry.rank <= 3
                    ? Candy.yellow
                    : Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
          SizedBox(width: 7 * s),
          PlayerAvatar(
              iconKey: entry.avatarEmoji,
              color: entry.avatarColor,
              size: 36 * s),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  me ? '${entry.name} (You)' : entry.name,
                  style: Candy.ui(
                      size: 13.5 * s,
                      weight: FontWeight.w800,
                      color: me ? Candy.titleText : Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1 * s),
                Text(
                  'Lv ${entry.level}',
                  style: Candy.ui(
                      size: 11 * s,
                      color: Colors.white.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.valueFor(metric)}',
                style: Candy.display(
                    size: 16 * s, color: Colors.white, height: 1),
              ),
              SizedBox(height: 1 * s),
              Text(
                metric == LeaderboardMetric.highScore ? 'pts' : 'pops',
                style: Candy.ui(
                    size: 10.5 * s,
                    color: Colors.white.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
