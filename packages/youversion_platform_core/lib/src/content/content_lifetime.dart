/// How long a Bible content response may be kept, from its HTTP caching headers.
///
/// Same rules as the React Native, Swift and Kotlin SDKs (ADR 0020): `max-age`
/// minus `Age`, clamped at zero; seven days when there is no usable `max-age`;
/// `no-cache` and `no-store` are never stored; `Expires` and `Date` are ignored.
const Duration defaultContentLifetime = Duration(days: 7);

/// Lifetime of a response with the given `Cache-Control` and `Age` headers, or
/// `null` when the response must not be stored.
Duration? contentLifetime({String? cacheControl, String? age}) {
  final directives = <String, String?>{};
  for (final part in (cacheControl ?? '').split(',')) {
    final eq = part.indexOf('=');
    final name = (eq == -1 ? part : part.substring(0, eq)).trim().toLowerCase();
    if (name.isNotEmpty) {
      directives[name] = eq == -1 ? null : part.substring(eq + 1).trim();
    }
  }
  if (directives.containsKey('no-store') || directives.containsKey('no-cache')) {
    return null;
  }

  final maxAgeSeconds = _parseSeconds(directives['max-age']);
  if (maxAgeSeconds == null) return defaultContentLifetime;

  final ageSeconds = _parseSeconds(age) ?? 0;
  final remaining = maxAgeSeconds - ageSeconds;
  return Duration(seconds: remaining < 0 ? 0 : remaining);
}

/// RFC 9111 §5.2: accepts the quoted-string argument form (`max-age="3600"`).
int? _parseSeconds(String? value) {
  if (value == null) return null;
  var unquoted = value;
  if (unquoted.length >= 2 && unquoted.startsWith('"') && unquoted.endsWith('"')) {
    unquoted = unquoted.substring(1, unquoted.length - 1);
  }
  return RegExp(r'^\d+$').hasMatch(unquoted) ? int.parse(unquoted) : null;
}
