import 'package:flutter/widgets.dart';

import '../../../core/l10n_ext.dart';
import '../domain/staff.dart';

/// Localized display name for a [StaffRole].
String roleLabel(BuildContext context, StaffRole role) => switch (role) {
  StaffRole.owner => context.l10n.roleOwner,
  StaffRole.manager => context.l10n.roleManager,
  StaffRole.server => context.l10n.roleServer,
};
