import 'package:clearguard/data/repositories/blocklist_repository.dart';
import 'package:flutter/foundation.dart';

class BlocklistViewModel extends ChangeNotifier {
  BlocklistViewModel({required BlocklistRepository blocklistRepository})
      : _blocklistRepository = blocklistRepository;

  final BlocklistRepository _blocklistRepository;

  List<String> _domains = const [];
  bool _isLoading = false;
  String _query = '';

  bool get isLoading => _isLoading;
  int get totalCount => _domains.length;

  List<String> get filteredDomains {
    if (_query.isEmpty) return _domains;
    final needle = _query.toLowerCase();
    return _domains.where((d) => d.contains(needle)).toList();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _domains = await _blocklistRepository.effectiveBlockedDomains();

    _isLoading = false;
    notifyListeners();
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }
}
