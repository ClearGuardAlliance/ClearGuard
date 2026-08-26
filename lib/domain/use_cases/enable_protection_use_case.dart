import '../../data/repositories/blocklist_repository.dart';
import '../../data/repositories/protection_repository.dart';

/// Turns blocking on: resolves the effective blocklist and starts the VPN
/// and screen monitor. Never gated — see ProtectionRepository.enable.
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
