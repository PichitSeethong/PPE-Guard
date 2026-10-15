import 'package:flutter/foundation.dart';

class RefreshSignal {
  RefreshSignal._();

  static final notifier = ValueNotifier<int>(0);

  static void publish() => notifier.value += 1;
}
