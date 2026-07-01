import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/leaderboard_controller.dart';
import '../../app/theme.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../widgets/glass.dart';
import '../widgets/player_avatar.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<LeaderboardMetric>(
              segments: const [
                ButtonSegment(
                    value: LeaderboardMetric.highScore,
                    label: Text('Top Score'),
                    icon: Icon(Icons.emoji_events)),
                ButtonSegment(
                    value: LeaderboardMetric.totalPops,
                    label: Text('Total Pops'),
                    icon: Icon(Icons.bubble_chart)),
              ],
              selected: {_metric},
              onSelectionChanged: (s) => setState(() => _metric = s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<LeaderboardScope>(
              segments: const [
                ButtonSegment(
                    value: LeaderboardScope.local,
                    label: Text('Local'),
                    icon: Icon(Icons.location_on)),
                ButtonSegment(
                    value: LeaderboardScope.global,
                    label: Text('Global'),
                    icon: Icon(Icons.public)),
              ],
              selected: {_scope},
              onSelectionChanged: (s) => setState(() => _scope = s.first),
            ),
          ),
          Expanded(
            child: entries.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Could not load leaderboard\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54)),
              ),
              data: (list) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _LeaderboardRow(entry: list[i], metric: _metric),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.metric});
  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final me = entry.isCurrentPlayer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        radius: 14,
        blur: 14,
        shadow: false,
        tint: me ? AppColors.accent : Colors.white,
        borderColor: me ? AppColors.accent : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  color: entry.rank <= 3 ? AppColors.gold : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PlayerAvatar(
                iconKey: entry.avatarEmoji,
                color: entry.avatarColor,
                size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    me ? '${entry.name} (You)' : entry.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: me ? FontWeight.bold : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Lv ${entry.level}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.valueFor(metric)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  metric == LeaderboardMetric.highScore ? 'pts' : 'pops',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
