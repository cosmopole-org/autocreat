import 'dart:convert' show json;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web/web.dart' as web;

/// Platform-aware token storage.
///
/// Web strategy
/// ───────────────────────────────────────────────────────────────────────────
/// dart2js compiles Dart into an IIFE whose global scope resolves `window`
/// correctly, but `package:web`'s `Storage.getItem` returns null even for keys
/// that JavaScript's `localStorage.getItem` finds.  The root cause is an
/// interop mismatch in this Flutter/dart2js build environment.
///
/// Workaround: keep an in-memory Dart static map as the source-of-truth for
/// tokens within a single page session.  On login Flutter writes to both the
/// cache and the real localStorage (so future page reloads can bootstrap via
/// a re-login triggered by the auth flow).  All reads in the same session
/// come from the cache, which always works.
///
/// Native
/// ───────────────────────────────────────────────────────────────────────────
/// Uses [FlutterSecureStorage] (Keychain / Android Keystore).
class TokenStorage {
  /// In-memory token cache for the current page session (web only).
  static final Map<String, String> _cache = {};

  final FlutterSecureStorage _secure;

  const TokenStorage() : _secure = const FlutterSecureStorage();

  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      final v = _cache[key];
      // ignore: avoid_print
      print('[TOK] read $key => ${v != null ? "HIT(${v.length})" : "MISS"} cache=${_cache.keys.toList()}');
      return v;
    }
    return _secure.read(key: key);
  }

  Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      _cache[key] = value;
      // Also persist to localStorage so external tooling (tests, browser
      // devtools) can inspect tokens.  The format matches shared_preferences_web.
      _tryLsSet('flutter.$key', value);
    } else {
      await _secure.write(key: key, value: value);
    }
  }

  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      _cache.remove(key);
      _tryLsRemove('flutter.$key');
    } else {
      await _secure.delete(key: key);
    }
  }

  Future<void> deleteAll() async {
    if (kIsWeb) {
      _cache.clear();
      _tryLsClearFlutterKeys();
    } else {
      await _secure.deleteAll();
    }
  }

  // ── localStorage helpers (best-effort; failures are silently ignored) ─────

  static void _tryLsSet(String lsKey, String value) {
    try {
      web.window.localStorage.setItem(lsKey, json.encode(value));
    } catch (_) {}
  }

  static void _tryLsRemove(String lsKey) {
    try {
      web.window.localStorage.removeItem(lsKey);
    } catch (_) {}
  }

  static void _tryLsClearFlutterKeys() {
    try {
      final toRemove = <String>[];
      for (var i = 0; i < web.window.localStorage.length; i++) {
        final k = web.window.localStorage.key(i);
        if (k != null && k.startsWith('flutter.')) toRemove.add(k);
      }
      for (final k in toRemove) {
        web.window.localStorage.removeItem(k);
      }
    } catch (_) {}
  }
}
