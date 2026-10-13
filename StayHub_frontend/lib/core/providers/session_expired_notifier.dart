import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void expire() {
    state = true;
  }

  void reset() {
    state = false;
  }
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, bool>(
  () {
    return SessionExpiredNotifier();
  },
);
