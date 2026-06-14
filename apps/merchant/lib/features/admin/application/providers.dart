import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/staff_repository.dart';
import '../domain/staff.dart';

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepository(ref.watch(databaseProvider)),
);

/// The staff roster, live.
final staffRosterProvider = StreamProvider<List<Staff>>(
  (ref) => ref.watch(staffRepositoryProvider).watchStaff(),
);

/// The currently signed-in staff member, or null when nobody is signed in.
class SessionController extends Notifier<Staff?> {
  @override
  Staff? build() => null;

  /// Returns the matched staff on success (and signs them in), else null.
  Future<Staff?> signInWithPin(String pin) async {
    final staff = await ref.read(staffRepositoryProvider).findByPin(pin);
    if (staff != null) state = staff;
    return staff;
  }

  /// Sign a specific staff member in directly (used right after creating the
  /// first owner during bootstrap).
  void setActive(Staff staff) => state = staff;

  void signOut() => state = null;
}

final sessionProvider = NotifierProvider<SessionController, Staff?>(
  SessionController.new,
);

/// The single role the UI checks. **Bootstrap:** an empty roster (fresh
/// install) means full access, so the app is never locked out and behaves
/// exactly as before roles existed. Once staff exist, the everyday baseline is
/// [StaffRole.server] until someone signs in with a PIN.
///
/// This is the one place the role source is decided — a future online build
/// can derive it from backend auth here without touching any call site.
final currentRoleProvider = Provider<StaffRole>((ref) {
  final roster = ref.watch(staffRosterProvider).value ?? const [];
  if (roster.isEmpty) return StaffRole.owner;
  return ref.watch(sessionProvider)?.role ?? StaffRole.server;
});

/// Whether the current role may do [permission].
final canProvider = Provider.family<bool, AppPermission>(
  (ref, permission) => allows(ref.watch(currentRoleProvider), permission),
);
