import 'package:clearguard/data/repositories/blocklist_repository.dart';
import 'package:clearguard/data/repositories/protection_repository.dart';

class EnableProtectionUseCase {
  EnableProtectionUseCase({
    required ProtectionRepository protectionRepository,
    required BlocklistRepository blocklistRepository,
  })  : _protectionRepository = protectionRepository,
        _blocklistRepository = blocklistRepository;

  final ProtectionRepository _protectionRepository;
  final BlocklistRepository _blocklistRepository;

  Future<void> call() async {
    final domains = await _blocklistRepository.effectiveBlockedDomains();
    await _protectionRepository.enable(domains);
  }
}
