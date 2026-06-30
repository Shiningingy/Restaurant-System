import 'package:drift/drift.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// All money columns store integer cents (docs/PRINCIPLES.md); this
/// converter surfaces them as [domain.Money] in the generated row classes.
class MoneyConverter extends TypeConverter<domain.Money, int> {
  const MoneyConverter();

  @override
  domain.Money fromSql(int fromDb) => domain.Money(fromDb);

  @override
  int toSql(domain.Money value) => value.cents;
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MenuItemRow')
class MenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text()();
  IntColumn get price => integer().map(const MoneyConverter())();

  /// Human item number (e.g. "A01"); optional. Not the internal sort order.
  TextColumn get code => text().nullable()();

  /// Optional second name line (e.g. a native-language name).
  TextColumn get nameSecondary => text().nullable()();

  /// Optional longer description (ingredients, notes) shown on the menu.
  TextColumn get description => text().nullable()();
  TextColumn get sku => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// User-defined renamable text fields on a menu item (Description,
/// Ingredients, …). Part of the synced menu_item aggregate.
@DataClassName('MenuItemAttributeRow')
class MenuItemAttributes extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(MenuItems, #id)();
  TextColumn get label => text()();
  TextColumn get value => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Renamable images attached to a menu item. [path] points at a file in the
/// app documents dir; the `(sha, ext)` content address rides the menu_item sync
/// so the bytes can travel through the `menu-photos` bucket to other devices.
@DataClassName('MenuItemImageRow')
class MenuItemImages extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(MenuItems, #id)();
  TextColumn get label => text()();
  // Local file path. Empty ("") on a row that arrived via sync but whose bytes
  // haven't been downloaded from the bucket yet (reconciled after a pull).
  TextColumn get path => text()();
  // Content hash + extension for cross-device sync: the bytes live in the
  // `menu-photos` bucket keyed by `<sha><ext>`, so any device can tell from the
  // hash alone whether it already has the file. Null on legacy rows until the
  // backfill computes it from the local file.
  TextColumn get sha => text().nullable()();
  TextColumn get ext => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ModifierGroupRow')
class ModifierGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get minSelect => integer().withDefault(const Constant(0))();
  IntColumn get maxSelect => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ModifierRow')
class Modifiers extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(ModifierGroups, #id)();
  TextColumn get name => text()();
  IntColumn get priceDelta => integer().map(const MoneyConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MenuItemModifierGroupRow')
class MenuItemModifierGroups extends Table {
  TextColumn get itemId => text().references(MenuItems, #id)();
  TextColumn get groupId => text().references(ModifierGroups, #id)();

  @override
  Set<Column<Object>> get primaryKey => {itemId, groupId};
}

@DataClassName('DiningTableRow')
class DiningTables extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OrderRow')
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<domain.OrderType>()();
  TextColumn get status => textEnum<domain.OrderStatus>()();
  TextColumn get tableId => text().nullable().references(DiningTables, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get taxRateBp => integer()();
  IntColumn get serviceFeeBp => integer().withDefault(const Constant(0))();
  IntColumn get subtotal => integer().map(const MoneyConverter())();
  IntColumn get discount =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  IntColumn get serviceFee =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  IntColumn get tax => integer().map(const MoneyConverter())();
  IntColumn get total => integer().map(const MoneyConverter())();

  /// A tip the customer chose at the kiosk / online checkout, carried for the
  /// payment sheet to pre-fill at settlement. Not part of [total].
  IntColumn get requestedTip =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();

  /// Cash-rounding adjustment applied at a cash payment (signed). Amount owed
  /// is [total] + this. Not part of [total].
  IntColumn get cashRounding =>
      integer().map(const MoneyConverter()).withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OrderLineRow')
class OrderLines extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get menuItemId => text()();
  TextColumn get nameSnapshot => text()();
  IntColumn get priceSnapshot => integer().map(const MoneyConverter())();
  IntColumn get qty => integer()();
  IntColumn get lineTotal => integer().map(const MoneyConverter())();
  TextColumn get status => textEnum<domain.OrderLineStatus>()();

  /// A comped (on-the-house) line: still active, but free to the customer.
  /// [lineTotal] keeps the original price so the comp's worth is recoverable.
  BoolColumn get comped => boolean().withDefault(const Constant(false))();

  /// Item code + second name line, snapshotted at sale time.
  TextColumn get codeSnapshot => text().nullable()();
  TextColumn get nameSecondarySnapshot => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Id of the payment that settled this line when the bill is split by item;
  /// null while unpaid. Best-effort record — the order still closes on balance.
  TextColumn get settledByPaymentId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OrderLineModifierRow')
class OrderLineModifiers extends Table {
  TextColumn get id => text()();
  TextColumn get lineId => text().references(OrderLines, #id)();
  TextColumn get nameSnapshot => text()();
  IntColumn get priceDeltaSnapshot => integer().map(const MoneyConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Persisted print queue: jobs survive restarts, failed jobs can be
/// retried from Settings. The payload is the fully rendered ESC/POS byte
/// stream, so a retry reprints the exact original document.
@DataClassName('PrintJobRow')
class PrintJobs extends Table {
  TextColumn get id => text()();
  TextColumn get kind => textEnum<domain.PrintJobKind>()();
  TextColumn get status => textEnum<domain.PrintJobStatus>()();
  TextColumn get orderId => text().nullable()();
  BlobColumn get payload => blob()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Append-only journal of local writes, for optional cloud sync (Phase 5).
/// Each row is one change to a synced aggregate; [payload] is the full
/// JSON of the row/aggregate for an upsert, null for a delete. [syncedAt]
/// is set once the change has been pushed to the restaurant's Supabase.
/// The local SQLite DB is always the source of truth — this table is
/// strictly additive (docs/PRINCIPLES.md).
@DataClassName('SyncLogRow')
class SyncLog extends Table {
  TextColumn get id => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => textEnum<domain.SyncOp>()();
  TextColumn get payload => text().nullable()();

  /// Microseconds since epoch. Stored as int (not a DateTime column,
  /// which drift truncates to whole seconds) so writes within the same
  /// second keep a strict order — the change feed needs sub-second
  /// precision for cursors and last-write-wins.
  IntColumn get occurredAtUs => integer()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local staff roster for role-based access (PIN sign-in). [role] is a
/// StaffRole enum name; [pinHash] is sha256("$id:$pin"), never plaintext.
/// Local-only — not part of the cloud-sync journal this phase.
@DataClassName('StaffRow')
class Staff extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get pinHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get method => textEnum<domain.PaymentMethod>()();
  TextColumn get status => textEnum<domain.PaymentStatus>()();
  IntColumn get amount => integer().map(const MoneyConverter())();
  IntColumn get tip => integer().map(const MoneyConverter())();
  TextColumn get terminalRef => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
