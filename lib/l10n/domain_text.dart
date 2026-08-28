import 'package:clearguard/domain/models/trigger_app.dart';
import 'package:clearguard/domain/models/trigger_apps_report.dart';
import 'package:clearguard/domain/models/wellbeing_tip.dart';
import 'package:clearguard/l10n/generated/app_localizations.dart';

extension TriggerAppCategoryText on TriggerAppCategory {
  String label(AppLocalizations l10n) => switch (this) {
        TriggerAppCategory.socialMedia => l10n.categorySocialMedia,
        TriggerAppCategory.dating => l10n.categoryDating,
        TriggerAppCategory.messaging => l10n.categoryMessaging,
        TriggerAppCategory.circumvention => l10n.categoryCircumvention,
      };
}

extension TriggerAppsRiskLevelText on TriggerAppsRiskLevel {
  String label(AppLocalizations l10n) => switch (this) {
        TriggerAppsRiskLevel.none => l10n.riskLevelNone,
        TriggerAppsRiskLevel.low => l10n.riskLevelLow,
        TriggerAppsRiskLevel.medium => l10n.riskLevelMedium,
        TriggerAppsRiskLevel.high => l10n.riskLevelHigh,
      };
}

extension WellbeingTipText on WellbeingTip {
  String title(AppLocalizations l10n) => switch (this) {
        WellbeingTip.urgeSurfing => l10n.tipUrgeSurfingTitle,
        WellbeingTip.halt => l10n.tipHaltTitle,
        WellbeingTip.mapTriggers => l10n.tipMapTriggersTitle,
        WellbeingTip.talkBeforeNeeding => l10n.tipTalkBeforeNeedingTitle,
        WellbeingTip.phoneOutOfRoom => l10n.tipPhoneOutOfRoomTitle,
        WellbeingTip.relapseNotFailure => l10n.tipRelapseNotFailureTitle,
        WellbeingTip.ifThenPlan => l10n.tipIfThenPlanTitle,
        WellbeingTip.moveYourBody => l10n.tipMoveYourBodyTitle,
        WellbeingTip.selfCompassion => l10n.tipSelfCompassionTitle,
        WellbeingTip.writeItDown => l10n.tipWriteItDownTitle,
      };

  String body(AppLocalizations l10n) => switch (this) {
        WellbeingTip.urgeSurfing => l10n.tipUrgeSurfingBody,
        WellbeingTip.halt => l10n.tipHaltBody,
        WellbeingTip.mapTriggers => l10n.tipMapTriggersBody,
        WellbeingTip.talkBeforeNeeding => l10n.tipTalkBeforeNeedingBody,
        WellbeingTip.phoneOutOfRoom => l10n.tipPhoneOutOfRoomBody,
        WellbeingTip.relapseNotFailure => l10n.tipRelapseNotFailureBody,
        WellbeingTip.ifThenPlan => l10n.tipIfThenPlanBody,
        WellbeingTip.moveYourBody => l10n.tipMoveYourBodyBody,
        WellbeingTip.selfCompassion => l10n.tipSelfCompassionBody,
        WellbeingTip.writeItDown => l10n.tipWriteItDownBody,
      };
}
