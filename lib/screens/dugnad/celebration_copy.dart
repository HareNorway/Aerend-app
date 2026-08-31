import '../../l10n/app_localizations.dart';
import 'celebration_models.dart';

class CelebrationCopy {
  const CelebrationCopy(this.l10n);

  final AppLocalizations l10n;

  String title(PendingCelebration item) {
    switch (item.type) {
      case CelebrationType.t2:
        return l10n.celebrationTitleT2;
      case CelebrationType.t3:
        final kind = item.stringPayload('kind') ?? '';
        return kind == 'season_goal'
            ? l10n.celebrationTitleT3Season
            : l10n.celebrationTitleT3Weekly;
      case CelebrationType.t4:
        switch (item.stringPayload('new_state')) {
          case 'up':
            return l10n.celebrationTitleT4Up;
          case 'down':
            return l10n.celebrationTitleT4Down;
          default:
            return l10n.celebrationTitleT4Flat;
        }
      case CelebrationType.t5a:
        return l10n.celebrationTitleT5a;
      case CelebrationType.t5b:
        return l10n.celebrationTitleT5b;
      case CelebrationType.t6:
        return l10n.celebrationTitleT6;
      case CelebrationType.t7:
        return l10n.celebrationTitleT7;
      case CelebrationType.t8:
        return l10n.celebrationTitleT8;
      case CelebrationType.t9:
        return l10n.celebrationTitleT9;
      case CelebrationType.t10:
        return l10n.celebrationTitleT10;
      case CelebrationType.t11:
        return l10n.celebrationTitleT11;
      case CelebrationType.t12:
        return l10n.celebrationTitleT12;
      case CelebrationType.t13:
        return l10n.celebrationTitleT13;
      case CelebrationType.t14:
        return l10n.celebrationTitleT14;
      case CelebrationType.t15:
        final place = item.intPayload('final_position') ?? 3;
        if (place == 2) return l10n.celebrationTitleT15Second;
        if (place == 3) return l10n.celebrationTitleT15Third;
        return l10n.celebrationTitleT15(place);
      case CelebrationType.t16:
        return l10n.celebrationTitleT16;
      case CelebrationType.t1:
      case CelebrationType.unknown:
        return '';
    }
  }

  String body(PendingCelebration item) {
    switch (item.type) {
      case CelebrationType.t2:
        return l10n.celebrationBodyT2(
          item.stringPayload('badge_name') ?? '',
        );
      case CelebrationType.t3:
        final desc = item.stringPayload('description')?.trim() ??
            item.stringPayload('description_no')?.trim() ??
            '';
        if (desc.isNotEmpty) return desc;
        final kind = item.stringPayload('kind') ?? '';
        return kind == 'season_goal'
            ? l10n.celebrationSubtitleT3Season
            : l10n.celebrationSubtitleT3Weekly;
      case CelebrationType.t4:
        switch (item.stringPayload('new_state')) {
          case 'up':
            return l10n.celebrationBodyT4Up;
          case 'down':
            return l10n.celebrationBodyT4Down;
          default:
            return l10n.celebrationBodyT4Flat;
        }
      case CelebrationType.t5a:
        return l10n.celebrationBodyT5a;
      case CelebrationType.t5b:
        return l10n.celebrationBodyT5b;
      case CelebrationType.t6:
        return l10n.celebrationBodyT6;
      case CelebrationType.t7:
        return l10n.celebrationBodyT7;
      case CelebrationType.t8:
        return l10n.celebrationBodyT8;
      case CelebrationType.t10:
        return l10n.celebrationBodyT10;
      case CelebrationType.t11:
        return l10n.celebrationBodyT11;
      case CelebrationType.t12:
        return l10n.celebrationBodyT12;
      case CelebrationType.t9:
        return l10n.celebrationBodyT9;
      case CelebrationType.t15:
        final place = item.intPayload('final_position') ?? 3;
        return place == 2
            ? l10n.celebrationBodyT15Silver
            : l10n.celebrationBodyT15Bronze;
      case CelebrationType.t13:
        return l10n.celebrationBodyT13;
      case CelebrationType.t14:
        return l10n.celebrationBodyT14;
      case CelebrationType.t16:
        return '';
      case CelebrationType.t1:
      case CelebrationType.unknown:
        return '';
    }
  }

  String cta(PendingCelebration item) {
    switch (item.type) {
      case CelebrationType.t2:
        return l10n.celebrationCtaBadges;
      case CelebrationType.t3:
        final kind = item.stringPayload('kind') ?? '';
        return kind == 'season_goal'
            ? l10n.celebrationCtaSeasonGoals
            : l10n.celebrationCtaMissions;
      case CelebrationType.t4:
        return l10n.celebrationCtaForm;
      case CelebrationType.t5a:
      case CelebrationType.t5b:
        return l10n.celebrationCtaTable;
      case CelebrationType.t9:
      case CelebrationType.t15:
        return l10n.celebrationCtaSeason;
      case CelebrationType.t6:
        return l10n.celebrationCtaSto;
      case CelebrationType.t16:
        return l10n.celebrationCtaStoCard;
      case CelebrationType.t7:
        return l10n.celebrationCtaScorers;
      case CelebrationType.t8:
        return l10n.celebrationCtaAssists;
      case CelebrationType.t10:
      case CelebrationType.t11:
      case CelebrationType.t12:
        return l10n.celebrationCtaSeason;
      case CelebrationType.t13:
      case CelebrationType.t14:
      case CelebrationType.t1:
      case CelebrationType.unknown:
        return l10n.celebrationContinue;
    }
  }

  String eyebrow(PendingCelebration item) {
    switch (item.type) {
      case CelebrationType.t4:
        switch (item.stringPayload('new_state')) {
          case 'up':
            return l10n.celebrationEyebrowT4Up;
          case 'down':
            return l10n.celebrationEyebrowT4Down;
          default:
            return l10n.celebrationEyebrowT4Flat;
        }
      case CelebrationType.t5a:
        return l10n.celebrationEyebrowT5a;
      case CelebrationType.t5b:
        return l10n.celebrationEyebrowT5b;
      case CelebrationType.t6:
        return l10n.celebrationEyebrowT6;
      case CelebrationType.t7:
        return l10n.celebrationEyebrowT7;
      case CelebrationType.t8:
        return l10n.celebrationEyebrowT8;
      case CelebrationType.t15:
        return l10n.celebrationEyebrowT15;
      default:
        return '';
    }
  }
}
