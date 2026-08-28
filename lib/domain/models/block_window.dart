class BlockWindow {
  const BlockWindow({
    required this.enabled,
    required this.startMinutes,
    required this.endMinutes,
  });

  final bool enabled;
  final int startMinutes;
  final int endMinutes;

  static const defaultWindow = BlockWindow(
    enabled: false,
    startMinutes: 23 * 60,
    endMinutes: 6 * 60,
  );

  bool contains(DateTime time) {
    if (!enabled) return false;
    final minutes = time.hour * 60 + time.minute;
    if (startMinutes <= endMinutes) {
      return minutes >= startMinutes && minutes < endMinutes;
    }
    return minutes >= startMinutes || minutes < endMinutes;
  }

  BlockWindow copyWith({bool? enabled, int? startMinutes, int? endMinutes}) {
    return BlockWindow(
      enabled: enabled ?? this.enabled,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }
}
