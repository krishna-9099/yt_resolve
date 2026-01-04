// lib/cipher/n_throttle.dart
// yt_resolve — n parameter (throttling) decipher
// Ported STRATEGY from yt-dlp extractor/youtube/_n.py
//
// Purpose:
// Some googlevideo URLs include an `n` query param.
// If not transformed correctly, YouTube throttles or 403s the stream.
//
// This implementation:
// - Regex-extracts the n-transform function from player JS
// - Replays string/array operations (NO JS execution)
// - Caches operations per playerId

import 'dart:collection';

class NThrottleDecipher {
  static final Map<String, List<_NOp>> _cache = HashMap();

  /// Entry point
  static String decipher({
    required String n,
    required String playerJs,
    required String playerId,
  }) {
    final ops = _cache[playerId] ??= _extractOperations(playerJs);
    return _applyOperations(n, ops);
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Extract n-transform operations
  // ---------------------------------------------------------------------------

  static List<_NOp> _extractOperations(String js) {
    final fnName = _extractNFunctionName(js);
    if (fnName == null) {
      throw NThrottleException('n function name not found');
    }

    final fnBody = _extractFunctionBody(js, fnName);
    return _parseOperations(fnBody);
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Locate n function name
  // ---------------------------------------------------------------------------

  static String? _extractNFunctionName(String js) {
    // Matches patterns like: var nfunc=function(a){a=a.split("");...}
    final reg = RegExp(
      r'([a-zA-Z0-9$]{2,})\\s*=\\s*function\\(\\s*a\\s*\\)\\s*\\{[^}]*\\.split',
    );
    return reg.firstMatch(js)?.group(1);
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Extract function body (brace counting)
  // ---------------------------------------------------------------------------

  static String _extractFunctionBody(String js, String fnName) {
    final start = js.indexOf('$fnName=function');
    if (start < 0) throw NThrottleException('n function not found');

    final braceStart = js.indexOf('{', start);
    int depth = 0;
    for (int i = braceStart; i < js.length; i++) {
      if (js[i] == '{') depth++;
      if (js[i] == '}') depth--;
      if (depth == 0) {
        return js.substring(braceStart + 1, i);
      }
    }
    throw NThrottleException('Unbalanced braces in n function');
  }

  // ---------------------------------------------------------------------------
  // STEP 4: Parse operations from function body
  // ---------------------------------------------------------------------------

  static List<_NOp> _parseOperations(String body) {
    final ops = <_NOp>[];

    // reverse
    if (body.contains('.reverse()')) {
      ops.add(const _NOp(_NOpType.reverse));
    }

    // splice / slice
    final spliceReg = RegExp(r'\\.splice\\(0,([0-9]+)\\)');
    for (final m in spliceReg.allMatches(body)) {
      ops.add(_NOp(_NOpType.splice, int.parse(m.group(1)!)));
    }

    // swap pattern
    if (body.contains('%') && body.contains('[0]')) {
      ops.add(const _NOp(_NOpType.swap));
    }

    return ops;
  }

  // ---------------------------------------------------------------------------
  // STEP 5: Apply operations
  // ---------------------------------------------------------------------------

  static String _applyOperations(String n, List<_NOp> ops) {
    final chars = n.split('');

    for (final op in ops) {
      switch (op.type) {
        case _NOpType.reverse:
          chars.setAll(0, chars.reversed);
          break;
        case _NOpType.splice:
          chars.removeRange(0, op.arg!);
          break;
        case _NOpType.swap:
          if (chars.length > 1) {
            final idx = chars.length ~/ 2;
            final tmp = chars[0];
            chars[0] = chars[idx];
            chars[idx] = tmp;
          }
          break;
      }
    }

    return chars.join();
  }
}

// -----------------------------------------------------------------------------
// Internal models
// -----------------------------------------------------------------------------

enum _NOpType { reverse, splice, swap }

class _NOp {
  final _NOpType type;
  final int? arg;
  const _NOp(this.type, [this.arg]);
}

class NThrottleException implements Exception {
  final String message;
  NThrottleException(this.message);

  @override
  String toString() => 'NThrottleException: $message';
}
