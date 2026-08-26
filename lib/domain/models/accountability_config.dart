class AccountabilityConfig {
  const AccountabilityConfig({
    required this.pinHash,
    required this.webhookUrl,
    required this.partnerLabel,
    required this.sensitiveActionDelay,
  });

  final String pinHash;
  final String webhookUrl;
  final String partnerLabel;
  final Duration sensitiveActionDelay;

  static const Duration defaultDelay = Duration(minutes: 30);
  static const Duration minimumDelay = Duration(minutes: 15);

  AccountabilityConfig copyWith({
    String? pinHash,
    String? webhookUrl,
    String? partnerLabel,
    Duration? sensitiveActionDelay,
  }) {
    return AccountabilityConfig(
      pinHash: pinHash ?? this.pinHash,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      partnerLabel: partnerLabel ?? this.partnerLabel,
      sensitiveActionDelay: sensitiveActionDelay ?? this.sensitiveActionDelay,
    );
  }
}
