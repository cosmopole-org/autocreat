/// Simple in-memory token storage for the CLI (no Flutter/Keychain deps).
class TokenStorage {
  static final Map<String, String> _store = {};

  const TokenStorage();

  Future<String?> read({required String key}) async => _store[key];

  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  Future<void> deleteAll() async {
    _store.clear();
  }
}
