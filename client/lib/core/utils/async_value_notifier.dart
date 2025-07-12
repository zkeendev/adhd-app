import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A [ChangeNotifier] that wraps an [AsyncValue].
///
/// Useful for bridging Riverpod's [AsyncValue] with systems
/// that require a [Listenable], like GoRouter's `refreshListenable`.
class AsyncValueNotifier<T> extends ChangeNotifier {
  /// Creates an [AsyncValueNotifier] with an initial [AsyncValue].
  AsyncValueNotifier(this._value);

  AsyncValue<T> _value;

  /// The current [AsyncValue] held by this notifier.
  AsyncValue<T> get value => _value;

  /// Updates the internal [AsyncValue] and notifies listeners if [newValue] is different.
  void update(AsyncValue<T> newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }
}