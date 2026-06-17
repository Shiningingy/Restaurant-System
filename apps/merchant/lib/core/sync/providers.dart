import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'sync_codec.dart';
import 'sync_journal.dart';

/// One shared journal for the whole app, so its monotonic change clock is
/// global — every repository writes through this instance. Part of the core
/// sync kernel: always on, regardless of whether cloud sync is configured.
final syncJournalProvider = Provider<SyncJournal>(
  (ref) => SyncJournal(ref.watch(databaseProvider)),
);

final syncCodecProvider = Provider<SyncCodec>(
  (ref) => SyncCodec(ref.watch(databaseProvider)),
);
