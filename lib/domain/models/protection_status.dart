/// Runtime state of the blocking engine (VPN + screen monitor), as reported
/// by the platform layer. This reflects what is actually running on the
/// device, not what the user wants — see [PendingAction] for user intent
/// that has not taken effect yet.
enum ProtectionStatus {
  active,
  disabled,
  starting,
  error;

  bool get isActive => this == ProtectionStatus.active;
}
