import 'package:clearguard/data/repositories/blocklist_repository.dart';
import 'package:clearguard/data/repositories/protection_repository.dart';

class UpdateBlocklistUseCase {
  UpdateBlocklistUseCase({
    required ProtectionRepository protectionRepository,
    required BlocklistRepository blocklistRepository,
  })  : _protectionRepository = protectionRepository,
        _blocklistRepository = blocklistRepository;

  final ProtectionRepository _protectionRepository;
  final BlocklistRepository _blocklistRepository;

  Future<int> call() async {
    final domains = await _blocklistRepository.effectiveBlockedDomains();
    try {
      await _protectionRepository.syncBlocklist(domains);
    } on Exception {
      return domains.length;
    }
    return domains.length;
  }
}
