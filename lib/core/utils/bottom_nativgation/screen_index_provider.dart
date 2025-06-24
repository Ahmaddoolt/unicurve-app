import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void setToZero() {
    state = 0;
  }

  void setToOne() {
    state = 1;
  }

  void setToTwo() {
    state = 2;
  }

  void setToThree() {
    state = 3;
  }
}

final studentCounterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

final uniAdminCounterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

final adminboosCounterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});