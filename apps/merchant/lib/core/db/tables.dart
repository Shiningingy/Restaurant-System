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
  TextColumn get sku => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

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
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get taxRateBp => integer()();
  IntColumn get subtotal => integer().map(const MoneyConverter())();
  IntColumn get tax => integer().map(const MoneyConverter())();
  IntColumn get total => integer().map(const MoneyConverter())();
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
  TextColumn get note => text().nullable()();

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
