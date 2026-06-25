import 'package:restaurant_domain/restaurant_domain.dart' as domain;

/// Public Storage URL for a published item's photo, or null when it has none.
///
/// The merchant uploads item photos (content-addressed) to a **public-read**
/// `menu-photos` bucket on its own Supabase (docs/CLOUD_SECURITY.md), so this
/// URL needs no auth — `Image.network` fetches and caches it directly. [base]
/// is the connected storefront's Supabase URL.
String? menuPhotoUrl(String? base, domain.PublishedItem item) {
  final sha = item.imageSha;
  final ext = item.imageExt;
  if (base == null || base.isEmpty || sha == null || ext == null) return null;
  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return '$root/storage/v1/object/public/menu-photos/$sha$ext';
}
