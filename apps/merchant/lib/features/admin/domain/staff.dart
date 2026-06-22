/// Local staff identity and role-based access (merchant-only; not shared with
/// the customer app, so it lives here rather than in packages/domain).
///
/// Today a role is proven offline with a PIN. The design keeps `currentRole`
/// the single thing the UI checks, so a future online build can feed it from
/// backend auth instead without touching call sites.
library;

/// Access levels, owner highest.
enum StaffRole { owner, manager, server }

extension StaffRoleRank on StaffRole {
  /// Higher = more access. Used for `atLeast` comparisons.
  int get rank => switch (this) {
    StaffRole.owner => 3,
    StaffRole.manager => 2,
    StaffRole.server => 1,
  };

  bool atLeast(StaffRole other) => rank >= other.rank;
}

/// A staff member on this tablet.
class Staff {
  final String id;
  final String name;
  final StaffRole role;

  /// `sha256("$id:$pin")` — never the plaintext PIN. (4-digit PINs are
  /// brute-forceable by anyone with the DB file; hashing is hygiene, not the
  /// security boundary — that's the future backend.)
  final String pinHash;

  const Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.pinHash,
  });

  Staff copyWith({String? name, StaffRole? role, String? pinHash}) => Staff(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    pinHash: pinHash ?? this.pinHash,
  );
}

/// Things a role may be allowed to do. Checked via [allows].
enum AppPermission {
  /// Edit the menu (the whole Menu tab; order-taking is unaffected).
  editMenu,

  /// View the Reports tab (sales, takings, history).
  viewReports,

  /// Reverse a *paid* order (a true refund). Reserved — no call site yet;
  /// voiding an *unpaid* order is not gated (mis-entry correction).
  refundPaidOrder,

  /// Open the Admin tab.
  accessAdmin,

  /// Apply a discount above the threshold staff may grant on their own.
  largeDiscount,

  /// Add/edit/delete staff and change roles.
  manageStaff,

  /// Permanently delete a closed order from history (e.g. clearing test data).
  deleteHistory,
}

StaffRole _minRole(AppPermission permission) => switch (permission) {
  AppPermission.manageStaff || AppPermission.deleteHistory => StaffRole.owner,
  AppPermission.editMenu ||
  AppPermission.viewReports ||
  AppPermission.refundPaidOrder ||
  AppPermission.largeDiscount ||
  AppPermission.accessAdmin => StaffRole.manager,
};

/// Whether [role] satisfies [permission].
bool allows(StaffRole role, AppPermission permission) =>
    role.atLeast(_minRole(permission));
