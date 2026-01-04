// lib/normalize/ip_family.dart
// yt_resolve — IP family detection utilities
//
// Purpose:
// - Detect whether a URL is IPv4- or IPv6-bound
// - Detect the local preferred IP family
// - Help drop formats that will 403 due to IP-family mismatch

import 'dart:io';

/// IP family enum
enum IpFamily { ipv4, ipv6 }

/// Utilities for working with IP families
class IpFamilyUtil {
  const IpFamilyUtil._();

  /// Detect IP family from an IP literal string
  ///
  /// Returns null if the string does not look like an IP literal
  static IpFamily? fromIp(String ip) {
    // IPv6 literals always contain ':'
    if (ip.contains(':')) return IpFamily.ipv6;

    // IPv4 literals contain '.' and digits
    if (ip.contains('.')) return IpFamily.ipv4;

    return null;
  }

  /// Detect IP family from a googlevideo URL
  ///
  /// Uses the `ip` query parameter when present
  static IpFamily? fromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final ip = uri.queryParameters['ip'];
      if (ip == null) return null;
      return fromIp(ip);
    } catch (_) {
      return null;
    }
  }

  /// Detect the locally preferred IP family
  ///
  /// IMPORTANT:
  /// Dart does NOT provide a synchronous NetworkInterface API.
  /// This method is async by necessity.
  ///
  /// Heuristic:
  /// - If any non-loopback IPv6 address exists → prefer IPv6
  /// - Otherwise → IPv4
  static Future<IpFamily> local() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv6) {
            return IpFamily.ipv6;
          }
        }
      }
    } catch (_) {
      // Ignore and fall back to IPv4
    }

    return IpFamily.ipv4;
  }

  /// Check whether a URL matches the local IP family
  ///
  /// Returns true if:
  /// - URL has no IP binding
  /// - URL IP family matches local family
  static Future<bool> matchesLocal(String url) async {
    final urlFamily = fromUrl(url);
    if (urlFamily == null) return true;

    final localFamily = await local();
    return urlFamily == localFamily;
  }
}
