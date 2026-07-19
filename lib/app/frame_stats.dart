import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Profile-mode frame-time telemetry: aggregates [FrameTiming]s and logs one
/// summary line per second to logcat (`FRAMESTATS` tag), splitting UI (build)
/// vs raster thread time so jank can be attributed to Dart work or painting.
/// No-op outside profile mode — release ships nothing, debug numbers lie.
void installFrameStats() {
  if (!kProfileMode) return;

  var frames = 0;
  var uiSumMs = 0.0, uiMaxMs = 0.0;
  var rasterSumMs = 0.0, rasterMaxMs = 0.0;
  var jank = 0; // frames whose total time blew the 60fps budget
  var windowStart = DateTime.now();

  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      frames++;
      final ui = t.buildDuration.inMicroseconds / 1000.0;
      final raster = t.rasterDuration.inMicroseconds / 1000.0;
      uiSumMs += ui;
      rasterSumMs += raster;
      if (ui > uiMaxMs) uiMaxMs = ui;
      if (raster > rasterMaxMs) rasterMaxMs = raster;
      if (t.totalSpan.inMicroseconds > 16700) jank++;
    }
    final now = DateTime.now();
    if (now.difference(windowStart).inMilliseconds >= 1000 && frames > 0) {
      debugPrint(
        'FRAMESTATS f=$frames jank=$jank '
        'ui avg=${(uiSumMs / frames).toStringAsFixed(1)} max=${uiMaxMs.toStringAsFixed(1)} '
        'raster avg=${(rasterSumMs / frames).toStringAsFixed(1)} max=${rasterMaxMs.toStringAsFixed(1)}',
      );
      frames = 0;
      jank = 0;
      uiSumMs = uiMaxMs = rasterSumMs = rasterMaxMs = 0;
      windowStart = now;
    }
  });
}
