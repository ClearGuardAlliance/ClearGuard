/// Settings that make up the accountability layer. [pinHash] is never the
/// plaintext PIN — see SecureCredentialsService. The recommended setup is
/// for the accountability partner (not the device owner) to be the one who
/// types the PIN during onboarding, and for [webhookUrl] to point at a
/// channel the partner actually reads (a Discord/Slack/Telegram webhook).
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
