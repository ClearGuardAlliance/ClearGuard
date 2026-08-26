/// Every change that would weaken protection goes through a [PendingAction]
/// instead of applying immediately. This is the core accountability
/// mechanism: the request is announced to the accountability partner the
/// moment it is made, and only takes effect after [readyAt], giving the
/// partner a window to intervene and the requester a cooling-off period.
///
/// Actions that strengthen protection (re-enabling, adding a blocked
/// domain) never go through this — only actions that weaken it do.
enum PendingActionType {
  disableProtection,
  removeBlocklistDomain,
  changeWebhookUrl,
  increaseSensitiveActionDelay,
  decreaseSensitiveActionDelay,
  deactivateDeviceAdmin,
}

enum PendingActionState { pending, applied, cancelled }

class PendingAction {
  const PendingAction({
    required this.id,
    required this.type,
    required this.requestedAt,
    required this.readyAt,
    required this.state,
    this.payload = const {},
  });

  final String id;
  final PendingActionType type;
  final DateTime requestedAt;
  final DateTime readyAt;
  final PendingActionState state;
  final Map<String, String> payload;

  bool get isReadyToApply =>
      state == PendingActionState.pending &&
      DateTime.now().isAfter(readyAt);

  Duration get timeRemaining {
    final remaining = readyAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  PendingAction copyWith({PendingActionState? state}) {
    return PendingAction(
      id: id,
      type: type,
      requestedAt: requestedAt,
      readyAt: readyAt,
      state: state ?? this.state,
      payload: payload,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'requestedAt': requestedAt.toIso8601String(),
        'readyAt': readyAt.toIso8601String(),
        'state': state.name,
        'payload': payload,
      };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      id: json['id'] as String,
      type: PendingActionType.values.byName(json['type'] as String),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      readyAt: DateTime.parse(json['readyAt'] as String),
      state: PendingActionState.values.byName(json['state'] as String),
      payload: Map<String, String>.from(json['payload'] as Map? ?? {}),
    );
  }
}
