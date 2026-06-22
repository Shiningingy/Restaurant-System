import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// The default [domain.ObjectStore]: stores nothing. Selected whenever the
/// cloud isn't configured — promo photos simply stay device-local and the
/// promo-sync step becomes a no-op.
class NoopObjectStore implements domain.ObjectStore {
  const NoopObjectStore();

  @override
  Future<void> putObject(
    String key,
    List<int> bytes, {
    required String contentType,
  }) async {}

  @override
  Future<List<int>?> getObject(String key) async => null;

  @override
  Future<void> deleteObject(String key) async {}
}
