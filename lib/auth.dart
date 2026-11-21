import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple on-device account (name, email, salted password hash).
/// It lives on this phone only. Swap for Firebase/Supabase when you add a backend.
class Auth extends ChangeNotifier {
  bool loaded = false;
  bool signedIn = false;
  bool guest = false;
  String name = '';
  String email = '';
  SharedPreferences? _p;

  String get displayName => guest
      ? 'Guest'
      : (name.trim().isEmpty ? 'there' : name.trim().split(' ').first);
  String get initial =>
      displayName.isEmpty ? '?' : displayName[0].toUpperCase();

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    signedIn = _p!.getBool('session') ?? false;
    guest = _p!.getBool('guest') ?? false;
    name = _p!.getString('acct_name') ?? '';
    email = _p!.getString('acct_email') ?? '';
    loaded = true;
    notifyListeners();
  }

  String _hash(String salt, String pw) =>
      sha256.convert(utf8.encode('$salt:$pw')).toString();

  Future<String?> signUp(String name, String email, String pw) async {
    name = name.trim();
    email = email.trim().toLowerCase();
    if (name.isEmpty) return 'Please enter your name';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email))
      return 'Enter a valid email address';
    if (pw.length < 6) return 'Password must be at least 6 characters';
    if ((_p!.getString('acct_email') ?? '').isNotEmpty) {
      return 'An account already exists on this phone. Sign in instead.';
    }
    final rnd = Random.secure();
    final salt =
        base64Url.encode(List<int>.generate(16, (_) => rnd.nextInt(256)));
    await _p!.setString('acct_name', name);
    await _p!.setString('acct_email', email);
    await _p!.setString('acct_salt', salt);
    await _p!.setString('acct_hash', _hash(salt, pw));
    await _startSession(guest: false);
    return null;
  }

  Future<String?> signIn(String email, String pw) async {
    email = email.trim().toLowerCase();
    final saved = _p!.getString('acct_email');
    if (saved == null || saved.isEmpty)
      return 'No account on this phone yet. Create one first.';
    final salt = _p!.getString('acct_salt') ?? '';
    if (saved != email || _hash(salt, pw) != _p!.getString('acct_hash'))
      return 'Incorrect email or password';
    await _startSession(guest: false);
    return null;
  }

  Future<void> continueAsGuest() => _startSession(guest: true);

  Future<void> _startSession({required bool guest}) async {
    this.guest = guest;
    signedIn = true;
    name = _p!.getString('acct_name') ?? '';
    email = _p!.getString('acct_email') ?? '';
    await _p!.setBool('session', true);
    await _p!.setBool('guest', guest);
    notifyListeners();
  }

  Future<void> updateName(String n) async {
    name = n.trim();
    await _p!.setString('acct_name', name);
    notifyListeners();
  }

  Future<void> signOut() async {
    signedIn = false;
    guest = false;
    await _p!.setBool('session', false);
    await _p!.setBool('guest', false);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    for (final k in ['acct_name', 'acct_email', 'acct_salt', 'acct_hash']) {
      await _p!.remove(k);
    }
    name = '';
    email = '';
    await signOut();
  }
}
