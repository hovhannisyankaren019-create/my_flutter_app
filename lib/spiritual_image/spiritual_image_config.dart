/// Public Worker URL only. Cloudflare credentials stay on the Worker.
class SpiritualImageConfig {
  static const endpoint = String.fromEnvironment(
    'SPIRITUAL_IMAGE_URL',
    defaultValue: 'https://ararat-bible-spiritual-image.araratbible.workers.dev',
  );
  static const gateSecret = String.fromEnvironment(
    'SPIRITUAL_IMAGE_GATE',
    defaultValue: '',
  );

  static bool get isConfigured => endpoint.trim().isNotEmpty;

  static String get generateEndpoint {
    final base = endpoint.replaceFirst(RegExp(r'/$'), '');
    return '$base/generate-image';
  }

  static String get findEndpoint {
    final base = endpoint.replaceFirst(RegExp(r'/$'), '');
    return '$base/find-image';
  }
}
