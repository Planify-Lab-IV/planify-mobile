String? resolveAvatarUrl(String? raw, String baseUrl) {
  if (raw == null) return null;

  final scheme = Uri.tryParse(raw)?.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') return raw;

  final normalizedBaseUrl = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
  return '$normalizedBaseUrl$normalizedPath';
}
