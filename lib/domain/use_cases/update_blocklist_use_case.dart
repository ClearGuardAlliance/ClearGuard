import '../../data/repositories/blocklist_repository.dart';
import '../../data/repositories/protection_repository.dart';

/// Re-fetches the remote blocklist (if configured) and pushes the merged
/// result into the running VPN. Growing the blocklist is never gated;
/// shrinking it only happens through RequestSensitiveActionUseCase.
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
    await _protectionRepository.syncBlocklist(domains);
    return domains.length;
  }
}
