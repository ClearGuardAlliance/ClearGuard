import 'package:clearguard/data/repositories/protection_streak_repository.dart';
import 'package:clearguard/domain/models/protection_streak.dart';
import 'package:flutter/foundation.dart';

class StreakHistoryViewModel extends ChangeNotifier {
  StreakHistoryViewModel({required ProtectionStreakRepository repository})
      : _repository = repository;

  final ProtectionStreakRepository _repository;

  Set<DateTime> _activeDays = {};
  ProtectionStreak? _streak;
  bool _isLoading = false;

  Set<DateTime> get activeDays => _activeDays;
  ProtectionStreak? get streak => _streak;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _activeDays = await _repository.activeDays();
    _streak = await _repository.current();

    _isLoading = false;
    notifyListeners();
  }
}
