import '../../../l10n/app_localizations.dart';
import '../data/groups_repository.dart';

String groupErrorText(AppLocalizations l10n, Object error) {
  return switch (groupErrorFrom(error)) {
    GroupError.invalidInvite => l10n.errorInvalidInvite,
    GroupError.lastAdmin => l10n.errorLastAdmin,
    GroupError.notAdmin => l10n.errorNotAdmin,
    GroupError.notAMember => l10n.errorNotAMember,
    GroupError.unknown => l10n.errorGeneric,
  };
}
