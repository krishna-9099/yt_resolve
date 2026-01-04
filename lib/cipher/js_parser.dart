enum ActionType { swap, slice, reverse, splice, rotate }

class Action {
  final ActionType type;
  final int? arg;

  Action(this.type, [this.arg]);

  @override
  String toString() => 'Action($type, $arg)';
}

class JsParser {
  /// Parses a (heuristic) sequence of actions from player JS code.
  ///
  /// This is intentionally simple and recognizes common patterns used in
  /// YouTube player JS: swap, slice, splice (drop first N elements), reverse,
  /// and simple rotations (push/shift). It also attempts to evaluate simple
  /// numeric variables like `var n = 2;` so calls like `a.splice(0,n)` are
  /// handled.
  static List<Action> parseActions(String js) {
    final List<Action> actions = [];

    // Pre-scan for simple numeric and string variable assignments
    final vars = <String, int>{};
    final strVars = <String, String>{};

    // numeric vars: (var|let|const) name = 2;
    final varNumReg = RegExp(
      r'(?:var|let|const)\s+([A-Za-z0-9_$]+)\s*=\s*(\d+)',
      multiLine: true,
    );
    for (final m in varNumReg.allMatches(js)) {
      final name = m.group(1)!;
      final val = int.tryParse(m.group(2) ?? '');
      if (val != null) vars[name] = val;
    }

    // string vars: (var|let|const) name = 'm'; or "m"
    final varStrReg = RegExp(r'''(?:var|let|const)\s+([A-Za-z0-9_$]+)\s*=\s*['"]([^'"]*)['"]''', multiLine: true);
    for (final m in varStrReg.allMatches(js)) {
      final name = m.group(1)!;
      final val = m.group(2) ?? '';
      strVars[name] = val;
    }

    // Find the helper object that defines transformations: var X = { ... };
    final candidateObjReg = RegExp(
      r'(?:var|let|const)\s+([A-Za-z0-9_\$]+)\s*=\s*\{([\s\S]{0,2000}?)\}\s*;',
      multiLine: true,
      dotAll: true,
    );
    // Candidate object search result is performed below; initialize holder structures.
    final methodMap = <String, ActionType>{};
    String? objName;
    int bestScore = 0;

    // Walk candidate object literals and select the best match by heuristics:
      // Score object literals by occurrence of known op keywords inside their bodies
      for (final m in candidateObjReg.allMatches(js)) {
        final name = m.group(1)!;
        final body = m.group(2) ?? '';
        var score = 0;
        if (body.contains('splice(')) score += 4;
        if (body.contains('reverse(') || body.contains('.reverse()')) score += 3;
        if (body.contains('slice(')) score += 3;
        if (body.contains('push') && body.contains('shift')) score += 2;
        if (body.contains('a[0]') && body.contains('%a.length')) score += 2;

        if (score > bestScore) {
          bestScore = score;
          objName = name;

          // Extract methods inside this object and map them to action types.
          final methodReg = RegExp(
            r'([A-Za-z0-9_\$]+)\s*:\s*function\s*\([^)]*\)\s*\{([\s\S]*?)\}',
            multiLine: true,
            dotAll: true,
          );
          methodMap.clear();
          for (final mm in methodReg.allMatches(body)) {
            final mname = mm.group(1)!;
            final methBody = mm.group(2) ?? '';

            if (methBody.contains('splice(')) {
              methodMap[mname] = ActionType.splice;
            } else if (methBody.contains('reverse(') ||
                methBody.contains('.reverse()')) {
              methodMap[mname] = ActionType.reverse;
            } else if (methBody.contains('return a.slice') ||
                methBody.contains('slice(')) {
              methodMap[mname] = ActionType.slice;
            } else if (methBody.contains('a[0]') &&
                methBody.contains('%a.length')) {
              methodMap[mname] = ActionType.swap;
            } else if (methBody.contains('push') && methBody.contains('shift')) {
              methodMap[mname] = ActionType.rotate;
            }
          }
        }
      }


    // Find candidate functions that operate on the signature. Look for a function
    // that contains split/join or references to the helper object or inline ops.
    final funcPatterns = [
      RegExp(r'function\s+[A-Za-z0-9_\$]*\s*\([A-Za-z0-9_]+\)\s*\{([^}]*)\}', multiLine: true, dotAll: true),
      RegExp(r'[A-Za-z0-9_\$]+\s*=\s*function\s*\([A-Za-z0-9_]+\)\s*\{([^}]*)\}', multiLine: true, dotAll: true),
      RegExp(r'[A-Za-z0-9_\$]+\s*:\s*function\s*\([A-Za-z0-9_]+\)\s*\{([^}]*)\}', multiLine: true, dotAll: true),
    ];
    for (final pattern in funcPatterns) {
      for (final f in pattern.allMatches(js)) {
        final fbody = f.group(1) ?? '';
        if ( (objName != null && fbody.contains(objName)) ||
          fbody.contains('split(') ||
          fbody.contains('a.reverse') ||
          fbody.contains('a.splice') ||
          fbody.contains('a.push')) {
        // 1) Helper object calls: X.method(a, arg)
        if (objName != null) {
          // allow for local aliases of the helper object
          final aliases = <String>{};
          final aliasReg1 = RegExp(r'var\s+([A-Za-z0-9_\$]+)\s*=\s*' + RegExp.escape(objName!));
          final aliasReg2 = RegExp(r'([A-Za-z0-9_\$]+)\s*=\s*' + RegExp.escape(objName!));
          final am1 = aliasReg1.firstMatch(fbody);
          final am2 = aliasReg2.firstMatch(fbody);
          if (am1 != null) aliases.add(am1.group(1)!);
          if (am2 != null) aliases.add(am2.group(1)!);
          aliases.add(objName!);

          final objPattern = aliases.map((s) => RegExp.escape(s)).join('|');

          // dot-style calls: OBJ.method(a,...)
          final dotCallReg = RegExp(r'(?:' + objPattern + r')\.([A-Za-z0-9_\$]+)\s*\(([^)]*)\)');
          // bracket-style calls: OBJ[<expr>](a,...)
          final bracketCallReg = RegExp(r'(?:' + objPattern + r')\s*\[\s*([^\]]+)\s*\]\s*\(([^)]*)\)');

          // member aliases: var c = OBJ[<expr>]; then c(...) should map to method (if we can evaluate)
          final memberAlias = <String, String>{};
          final memberAliasReg = RegExp(r'var\s+([A-Za-z0-9_\$]+)\s*=\s*' + RegExp.escape(objName!) + r'\s*\[\s*([^\]]+)\s*\]');
          for (final mm in memberAliasReg.allMatches(js)) {
            final expr = mm.group(2)!;
            final mname = _evalPropName(expr, vars, strVars);
            if (mname != null) memberAlias[mm.group(1)!] = mname;
          }

          // wrapper functions that forward to helper methods, e.g. function w(a){return OBJ.m(a);} or OBJ[expr]
          final wrapperMap = <String, String>{};
          final wrapperReg1 = RegExp(r'function\s+([A-Za-z0-9_\$]+)\s*\([^)]*\)\s*\{\s*return\s+' + RegExp.escape(objName!) + r'\.([A-Za-z0-9_\$]+)\s*\(([^)]*)\)\s*;?\s*\}', multiLine: true, dotAll: true);
          for (final mm in wrapperReg1.allMatches(js)) {
            wrapperMap[mm.group(1)!] = mm.group(2)!;
          }
          final wrapperReg2 = RegExp(r'function\s+([A-Za-z0-9_\$]+)\s*\([^)]*\)\s*\{\s*return\s+' + RegExp.escape(objName!) + r'\s*\[\s*([^\]]+)\s*\]\s*\(([^)]*)\)\s*;?\s*\}', multiLine: true, dotAll: true);
          for (final mm in wrapperReg2.allMatches(js)) {
            final expr = mm.group(2)!;
            final mname = _evalPropName(expr, vars, strVars);
            if (mname != null) wrapperMap[mm.group(1)!] = mname;
          }

          // Process dot-style calls
          for (final call in dotCallReg.allMatches(fbody)) {
            final mname = call.group(1)!;
            final rawArgs = call.group(2) ?? '';
            final parts = rawArgs.split(',');
            final candidate = parts.length >= 2 ? parts[1].trim() : parts[0].trim();
            final arg = candidate.isEmpty ? null : _evalArg(candidate, vars);
            final type = methodMap[mname];
            if (type != null) {
              actions.add(Action(type, arg));
            } else {
              if (mname.contains('reverse')) {
                actions.add(Action(ActionType.reverse));
              } else if (mname.contains('slice')) {
                actions.add(Action(ActionType.slice, arg));
              } else if (mname.contains('splice')) {
                actions.add(Action(ActionType.splice, arg));
              } else if (mname.contains('swap') || mname.contains('swapItems')) {
                actions.add(Action(ActionType.swap, arg));
              } else if (mname.contains('push') && mname.contains('shift')) {
                actions.add(Action(ActionType.rotate, arg ?? 1));
              }
            }
          }

          // Process bracket-style calls
          for (final call in bracketCallReg.allMatches(fbody)) {
            final rawKey = call.group(1)!;
            final mname = _evalPropName(rawKey, vars, strVars);
            if (mname == null) continue;
            final rawArgs = call.group(2) ?? '';
            final parts = rawArgs.split(',');
            final candidate = parts.length >= 2 ? parts[1].trim() : parts[0].trim();
            final arg = candidate.isEmpty ? null : _evalArg(candidate, vars);
            final type = methodMap[mname];
            if (type != null) {
              actions.add(Action(type, arg));
            } else {
              if (mname.contains('reverse')) {
                actions.add(Action(ActionType.reverse));
              } else if (mname.contains('slice')) {
                actions.add(Action(ActionType.slice, arg));
              } else if (mname.contains('splice')) {
                actions.add(Action(ActionType.splice, arg));
              } else if (mname.contains('swap') || mname.contains('swapItems')) {
                actions.add(Action(ActionType.swap, arg));
              } else if (mname.contains('push') && mname.contains('shift')) {
                actions.add(Action(ActionType.rotate, arg ?? 1));
              }
            }
          }

          // Process simple calls - detect calls to member aliases or wrapper functions
          final simpleCallReg = RegExp(r'(^|[^.A-Za-z0-9_\\$])([A-Za-z0-9_\\$]+)\s*\(([^)]*)\)');
          for (final call in simpleCallReg.allMatches(fbody)) {
            final name = call.group(2)!;
            final rawArgs = call.group(3) ?? '';
            if (memberAlias.containsKey(name)) {
              final mname = memberAlias[name]!;
              final parts = rawArgs.split(',');
              final candidate = parts.length >= 2 ? parts[1].trim() : parts[0].trim();
              final arg = candidate.isEmpty ? null : _evalArg(candidate, vars);
              final type = methodMap[mname];
              if (type != null) actions.add(Action(type, arg));
            } else if (wrapperMap.containsKey(name)) {
              final mname = wrapperMap[name]!;
              final parts = rawArgs.split(',');
              final candidate = parts.length >= 2 ? parts[1].trim() : parts[0].trim();
              final arg = candidate.isEmpty ? null : _evalArg(candidate, vars);
              final type = methodMap[mname];
              if (type != null) actions.add(Action(type, arg));
            }
          }
        }

        // 2) Inline array operations on `a` (reverse, slice, splice, push(shift()))
        // Match only calls that are not inside object method definitions (avoid matching
        // "reverse:function(a){a.reverse()}" inside helper object bodies).
        final inlineReverse = RegExp(r'(^|[^A-Za-z0-9_\$:\)\}])a\.reverse\s*\(\s*\)');
        final inlineSlice = RegExp(r'(^|[^A-Za-z0-9_\$:\)\}])a\.slice\s*\(\s*([^\)\s]+)\s*\)');
        final inlineSplice = RegExp(r'(^|[^A-Za-z0-9_\$:\)\}])a\.splice\s*\(\s*([^\)]+)\s*\)');
        final inlineRotate = RegExp(r'(^|[^A-Za-z0-9_\$:\)\}])a\.push\s*\(\s*a\.shift\s*\(\s*\)\s*\)');

        for (final m in inlineReverse.allMatches(fbody)) {
          // avoid matches that belong to method definitions inside helper objects
          final idx = m.start;
          final ctx = fbody.substring(idx - (idx > 30 ? 30 : idx), idx);
          if (ctx.contains('function') || ctx.contains(':')) continue;
          actions.add(Action(ActionType.reverse));
        }

        for (final m in inlineSlice.allMatches(fbody)) {
          final idx = m.start;
          final ctx = fbody.substring(idx - (idx > 30 ? 30 : idx), idx);
          if (ctx.contains('function') || ctx.contains(':')) continue;
          final arg = _evalArg(m.group(2) ?? m.group(1) ?? '', vars);
          actions.add(Action(ActionType.slice, arg));
        }

        for (final m in inlineSplice.allMatches(fbody)) {
          final idx = m.start;
          final ctx = fbody.substring(idx - (idx > 30 ? 30 : idx), idx);
          if (ctx.contains('function') || ctx.contains(':')) continue;
          final raw = m.group(2) ?? m.group(1) ?? '';
          // splice can be (0,n) or (n) or (start,count)
          final parts = raw.split(',');
          int? arg;
          if (parts.isNotEmpty) {
            // if first arg is 0 and second exists, take second; else take first
            final first = parts[0].trim();
            final second = parts.length > 1 ? parts[1].trim() : null;
            if (first == '0' && second != null) {
              arg = _evalArg(second, vars);
            } else {
              arg = _evalArg(first, vars);
            }
          }
          actions.add(Action(ActionType.splice, arg));
        }

        for (final m in inlineRotate.allMatches(fbody)) {
          final idx = m.start;
          final ctx = fbody.substring(idx - (idx > 30 ? 30 : idx), idx);
          if (ctx.contains('function') || ctx.contains(':')) continue;
          actions.add(Action(ActionType.rotate, 1));
        }

        return actions; // only the first relevant function
        }
      }
    }

    return actions;
  }

  static int? _evalArg(String raw, Map<String, int> vars) {
    raw = raw.trim();
    if (raw.isEmpty) return null;
    // direct integer
    final intVal = int.tryParse(raw);
    if (intVal != null) return intVal;

    // variable name
    final varMatch = RegExp(r'^([A-Za-z0-9_$]+)$').firstMatch(raw);
    if (varMatch != null) {
      final name = varMatch.group(1)!;
      return vars[name];
    }

    // simple arithmetic like n-1 or n+2
    final arith = RegExp(
      r'^([A-Za-z0-9_$]+)\s*([+-])\s*(\d+)$',
    ).firstMatch(raw);
    if (arith != null) {
      final name = arith.group(1)!;
      final op = arith.group(2)!;
      final rhs = int.parse(arith.group(3)!);
      final lhs = vars[name];
      if (lhs == null) return null;
      return op == '+' ? lhs + rhs : lhs - rhs;
    }

    return null; // unknown
  }

  static String? _evalPropName(String raw, Map<String, int> vars, Map<String, String> strVars) {
    raw = raw.trim();
    if (raw.isEmpty) return null;

    // string literal
    final lit = RegExp(r'''^['"]([^'"]+)['"]$''').firstMatch(raw);
    if (lit != null) return lit.group(1);

    // simple variable name pointing to a string
    final varMatch = RegExp(r'^([A-Za-z0-9_$]+)$').firstMatch(raw);
    if (varMatch != null) {
      final name = varMatch.group(1)!;
      if (strVars.containsKey(name)) return strVars[name];
    }

    // String.fromCharCode(N)
    final fromChar = RegExp(r'String\.fromCharCode\s*\(\s*(\d+)\s*\)').firstMatch(raw);
    if (fromChar != null) {
      final code = int.tryParse(fromChar.group(1) ?? '');
      if (code != null) return String.fromCharCode(code);
    }

    // concatenations like 'a' + 'b' or 'm' + x
    final parts = raw.split('+').map((s) => s.trim()).toList();
    if (parts.length > 1) {
      final sb = StringBuffer();
      for (var p in parts) {
        final pLit = RegExp(r'''^['"]([^'"]+)['"]$''').firstMatch(p);
        if (pLit != null) {
          sb.write(pLit.group(1));
          continue;
        }
        final pVar = RegExp(r'^([A-Za-z0-9_$]+)$').firstMatch(p);
        if (pVar != null && strVars.containsKey(pVar.group(1)!)) {
          sb.write(strVars[pVar.group(1)!]);
          continue;
        }
        final pFromChar = RegExp(r'String\.fromCharCode\s*\(\s*(\d+)\s*\)').firstMatch(p);
        if (pFromChar != null) {
          final code = int.tryParse(pFromChar.group(1) ?? '');
          if (code != null) {
            sb.write(String.fromCharCode(code));
            continue;
          }
        }
        // if unknown part, abort
        return null;
      }
      return sb.toString();
    }

    return null;
  }

  /// Apply a series of actions to a signature string and return the result.
  static String applyActions(String sig, List<Action> actions) {
    final chars = sig.split('');
    for (final a in actions) {
      switch (a.type) {
        case ActionType.swap:
          if (chars.isEmpty) break;
          final idx = (a.arg ?? 0) % chars.length;
          final tmp = chars[0];
          chars[0] = chars[idx];
          chars[idx] = tmp;
          break;
        case ActionType.slice:
          final n = a.arg ?? 0;
          if (n >= chars.length) {
            chars.clear();
          } else {
            final newChars = chars.sublist(n);
            chars
              ..clear()
              ..addAll(newChars);
          }
          break;
        case ActionType.splice:
          final n = a.arg ?? 0;
          // splice(0,n) has effect of removing first n elements
          if (n >= chars.length) {
            chars.clear();
          } else {
            final newChars = chars.sublist(n);
            chars
              ..clear()
              ..addAll(newChars);
          }
          break;
        case ActionType.reverse:
          final reversed = chars.reversed.toList();
          chars
            ..clear()
            ..addAll(reversed);
          break;
        case ActionType.rotate:
          final n = a.arg ?? 1;
          if (chars.isEmpty) break;
          final times = n % chars.length;
          for (var i = 0; i < times; i++) {
            final first = chars.removeAt(0);
            chars.add(first);
          }
          break;
      }
    }
    return chars.join();
  }
}
