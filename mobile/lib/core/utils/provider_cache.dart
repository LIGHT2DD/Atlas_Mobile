import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension RefCacheExtension<T> on Ref<T> {
  /// Keeps the provider state alive for [duration] after the last listener unmounts.
  /// Subsequent screen visits within [duration] resolve instantaneously (0ms)
  /// without re-triggering network spinners.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;

    onCancel(() {
      timer?.cancel();
      timer = Timer(duration, () {
        link.close();
      });
    });

    onResume(() {
      timer?.cancel();
      timer = null;
    });

    onDispose(() {
      timer?.cancel();
    });
  }
}
