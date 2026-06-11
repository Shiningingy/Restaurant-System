import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates a new entity id.
///
/// IDs are UUIDv4 created on-device, never database autoincrement —
/// required for offline-first operation and future sync without collisions.
String newId() => _uuid.v4();
