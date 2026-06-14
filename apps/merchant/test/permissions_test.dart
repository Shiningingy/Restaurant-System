import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/admin/domain/staff.dart';

void main() {
  group('role ordering', () {
    test('owner > manager > server', () {
      expect(StaffRole.owner.atLeast(StaffRole.manager), isTrue);
      expect(StaffRole.manager.atLeast(StaffRole.server), isTrue);
      expect(StaffRole.server.atLeast(StaffRole.manager), isFalse);
      expect(StaffRole.manager.atLeast(StaffRole.owner), isFalse);
      expect(StaffRole.server.atLeast(StaffRole.server), isTrue);
    });
  });

  group('permissions', () {
    test('owner can do everything', () {
      for (final p in AppPermission.values) {
        expect(allows(StaffRole.owner, p), isTrue, reason: p.name);
      }
    });

    test('manager can do everything except manage staff', () {
      expect(allows(StaffRole.manager, AppPermission.editMenu), isTrue);
      expect(allows(StaffRole.manager, AppPermission.viewReports), isTrue);
      expect(allows(StaffRole.manager, AppPermission.refundPaidOrder), isTrue);
      expect(allows(StaffRole.manager, AppPermission.accessAdmin), isTrue);
      expect(allows(StaffRole.manager, AppPermission.manageStaff), isFalse);
    });

    test('server can do none of the restricted things', () {
      for (final p in AppPermission.values) {
        expect(allows(StaffRole.server, p), isFalse, reason: p.name);
      }
    });
  });
}
