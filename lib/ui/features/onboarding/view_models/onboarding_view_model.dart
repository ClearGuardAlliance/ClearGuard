import 'package:clearguard/data/repositories/accountability_repository.dart';
import 'package:clearguard/data/repositories/protection_repository.dart';
import 'package:clearguard/domain/models/accountability_config.dart';
import 'package:clearguard/domain/use_cases/enable_protection_use_case.dart';
import 'package:flutter/foundation.dart';

enum OnboardingStep {
  accountabilitySetup,
  vpnPermission,
  screenMonitorPermission,
  done,
}

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required AccountabilityRepository accountabilityRepository,
    required ProtectionRepository protectionRepository,
    required EnableProtectionUseCase enableProtectionUseCase,
  })  : _accountabilityRepository = accountabilityRepository,
        _protectionRepository = protectionRepository,
        _enableProtectionUseCase = enableProtectionUseCase;

  final AccountabilityRepository _accountabilityRepository;
  final ProtectionRepository _protectionRepository;
  final EnableProtectionUseCase _enableProtectionUseCase;

  OnboardingStep _step = OnboardingStep.accountabilitySetup;
  OnboardingStep get step => _step;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> submitAccountabilitySetup({
    required String pin,
    required String pinConfirmation,
    required String webhookUrl,
    required String partnerLabel,
    required Duration delay,
  }) async {
    if (pin.length < 6) {
      _fail('O PIN precisa ter pelo menos 6 dígitos.');
      return false;
    }
    if (pin != pinConfirmation) {
      _fail('Os PINs não coincidem.');
      return false;
    }
    if (webhookUrl.isEmpty) {
      _fail('É preciso informar um webhook para notificar o parceiro.');
      return false;
    }
    if (delay < AccountabilityConfig.minimumDelay) {
      final minimumMinutes = AccountabilityConfig.minimumDelay.inMinutes;
      _fail('O tempo mínimo de espera é de $minimumMinutes min.');
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _accountabilityRepository.setUpAccountability(
        pin: pin,
        webhookUrl: webhookUrl,
        partnerLabel: partnerLabel,
        delay: delay,
      );
      _step = OnboardingStep.vpnPermission;
      return true;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> requestVpnPermission() async {
    final granted = await _protectionRepository.requestVpnPermission();
    if (granted) {
      _step = OnboardingStep.screenMonitorPermission;
      notifyListeners();
    }
    return granted;
  }

  Future<void> openScreenMonitorSettings() {
    return _protectionRepository.openScreenMonitorSettings();
  }

  Future<bool> confirmScreenMonitorPermission() async {
    final granted =
        await _protectionRepository.isScreenMonitorPermissionGranted();
    if (granted) {
      await _enableProtectionUseCase();
      _step = OnboardingStep.done;
      notifyListeners();
    }
    return granted;
  }

  void _fail(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
