// Generates the game's sound effects as small WAV files using only the Dart
// SDK. Run once to (re)create assets/audio/*.wav:
//
//     dart run tool/gen_audio.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;

void writeWav(String name, List<double> samples) {
  final dir = Directory('assets/audio');
  dir.createSync(recursive: true);

  final dataBytes = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    final v = samples[i].clamp(-1.0, 1.0);
    dataBytes.setInt16(i * 2, (v * 32767).round(), Endian.little);
  }
  final data = dataBytes.buffer.asUint8List();

  final byteRate = sampleRate * 2; // mono, 16-bit
  final header = BytesBuilder();
  void str(String s) => header.add(s.codeUnits);
  void u32(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.little);
    header.add(b.buffer.asUint8List());
  }

  void u16(int v) {
    final b = ByteData(2)..setUint16(0, v, Endian.little);
    header.add(b.buffer.asUint8List());
  }

  str('RIFF');
  u32(36 + data.length);
  str('WAVE');
  str('fmt ');
  u32(16); // PCM chunk size
  u16(1); // PCM
  u16(1); // mono
  u32(sampleRate);
  u32(byteRate);
  u16(2); // block align
  u16(16); // bits per sample
  str('data');
  u32(data.length);

  final out = BytesBuilder()
    ..add(header.toBytes())
    ..add(data);
  File('assets/audio/$name').writeAsBytesSync(out.toBytes());
  stdout.writeln('wrote assets/audio/$name (${samples.length} samples)');
}

/// A short, bright bubble "pop": a quick upward pitch blip with fast decay.
List<double> pop() {
  const dur = 0.12;
  final n = (sampleRate * dur).round();
  return List<double>.generate(n, (i) {
    final t = i / sampleRate;
    final freq = 480 + 700 * (t / dur);
    final env = exp(-30 * t);
    return 0.6 * env * sin(2 * pi * freq * t);
  });
}

/// A short descending three-note motif to signal failure.
List<double> gameOver() {
  const notes = [523.25, 415.30, 311.13]; // C5, G#4, D#4
  const noteDur = 0.16;
  final out = <double>[];
  for (final freq in notes) {
    final n = (sampleRate * noteDur).round();
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = exp(-6 * t) * (1 - t / noteDur);
      out.add(0.5 * env * sin(2 * pi * freq * t));
    }
  }
  return out;
}

void main() {
  writeWav('pop.wav', pop());
  writeWav('game_over.wav', gameOver());
  stdout.writeln('done');
}
