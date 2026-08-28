enum WellbeingTip {
  urgeSurfing,
  halt,
  mapTriggers,
  talkBeforeNeeding,
  phoneOutOfRoom,
  relapseNotFailure,
  ifThenPlan,
  moveYourBody,
  selfCompassion,
  writeItDown;

  static WellbeingTip forDay(DateTime date) {
    final startOfYear = DateTime(date.year);
    final dayOfYear = date.difference(startOfYear).inDays;
    return values[dayOfYear % values.length];
  }
}
