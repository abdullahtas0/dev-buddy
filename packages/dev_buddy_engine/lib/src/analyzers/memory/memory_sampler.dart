// packages/dev_buddy/lib/src/modules/memory/memory_sampler.dart
import 'dart:collection';

/// Maintains a sliding window of memory usage samples (in MB).
///
/// Pure computation - no platform dependency. The [MemoryModule] feeds
/// `ProcessInfo.currentRss` values into this.
class MemorySampler {
  final int maxSamples;
  final Queue<int> _samples = Queue();

  MemorySampler({this.maxSamples = 60});

  List<int> get samples => _samples.toList();
  int get latestMb => _samples.isEmpty ? 0 : _samples.last;

  void addSample(int memoryMb) {
    _samples.addLast(memoryMb);
    if (_samples.length > maxSamples) {
      _samples.removeFirst();
    }
  }

  /// True if every sample is >= the previous (memory never decreased).
  bool get isMonotonicallyGrowing {
    if (_samples.length < 3) return false;
    final list = _samples.toList();
    for (var i = 1; i < list.length; i++) {
      if (list[i] < list[i - 1]) return false;
    }
    return true;
  }

  /// Difference between latest and first sample in the window.
  int get growthRate {
    if (_samples.length < 2) return 0;
    return _samples.last - _samples.first;
  }

  void reset() => _samples.clear();
}
