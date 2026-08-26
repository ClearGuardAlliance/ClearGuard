enum ProtectionStatus {
  active,
  disabled,
  starting,
  error;

  bool get isActive => this == ProtectionStatus.active;
}
