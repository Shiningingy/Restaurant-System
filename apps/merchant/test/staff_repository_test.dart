import 'package:flutter_test/flutter_test.dart';
import 'package:merchant/features/admin/data/staff_repository.dart';
import 'package:merchant/features/admin/domain/staff.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import 'helpers/test_db.dart';

void main() {
  late StaffRepository repo;

  setUp(() {
    repo = StaffRepository(createTestDb());
  });

  tearDown(() => repo.db.close());

  Staff make(String name, StaffRole role, String pin) {
    final id = domain.newId();
    return Staff(
      id: id,
      name: name,
      role: role,
      pinHash: StaffRepository.hashPin(id, pin),
    );
  }

  test('roster starts empty (bootstrap)', () async {
    expect(await repo.staffCount(), 0);
    expect(await repo.ownerCount(), 0);
  });

  test('upsert and read back the roster', () async {
    await repo.upsert(make('Ann', StaffRole.owner, '1111'));
    await repo.upsert(make('Bob', StaffRole.manager, '2222'));
    await repo.upsert(make('Cara', StaffRole.server, '3333'));

    final all = await repo.all();
    expect(all, hasLength(3));
    expect(await repo.ownerCount(), 1);
    expect(all.firstWhere((s) => s.name == 'Bob').role, StaffRole.manager);
  });

  test('findByPin matches the right staff, rejects a wrong PIN', () async {
    final ann = make('Ann', StaffRole.owner, '1111');
    final bob = make('Bob', StaffRole.manager, '2222');
    await repo.upsert(ann);
    await repo.upsert(bob);

    expect((await repo.findByPin('1111'))?.id, ann.id);
    expect((await repo.findByPin('2222'))?.id, bob.id);
    expect(await repo.findByPin('9999'), isNull);
  });

  test('findByNameAndPin disambiguates two staff sharing a PIN', () async {
    // Ann and Bob both chose PIN 1234 — name is what tells them apart.
    final ann = make('Ann', StaffRole.owner, '1234');
    final bob = make('Bob', StaffRole.server, '1234');
    await repo.upsert(ann);
    await repo.upsert(bob);

    expect((await repo.findByNameAndPin('Ann', '1234'))?.id, ann.id);
    expect((await repo.findByNameAndPin('Bob', '1234'))?.id, bob.id);
    // Case-insensitive, space-trimmed.
    expect((await repo.findByNameAndPin('  bob ', '1234'))?.id, bob.id);
    // Right name, wrong PIN — rejected.
    expect(await repo.findByNameAndPin('Ann', '9999'), isNull);
    // Right PIN, wrong name — rejected.
    expect(await repo.findByNameAndPin('Cara', '1234'), isNull);
  });

  test('identical PINs hash differently per staff (salted by id)', () {
    final a = StaffRepository.hashPin('id-a', '1234');
    final b = StaffRepository.hashPin('id-b', '1234');
    expect(a, isNot(b));
    // and the plaintext never appears in the hash
    expect(a.contains('1234'), isFalse);
  });

  test('delete removes a staff member', () async {
    final ann = make('Ann', StaffRole.owner, '1111');
    await repo.upsert(ann);
    await repo.delete(ann.id);
    expect(await repo.staffCount(), 0);
  });
}
