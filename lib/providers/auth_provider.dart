import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_exception.dart';
import '../core/constants.dart';
import '../models/auth_session.dart';
import '../services/riot_auth_service.dart';

enum AuthStatus { initializing, signedOut, authenticating, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final RiotAuthService _authService;
  AuthStatus _status = AuthStatus.initializing;
  AuthSession? _session;
  List<SavedAccount> _accounts = const [];
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  List<SavedAccount> get accounts => _accounts;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _status == AuthStatus.authenticating;

  Future<void> initialize() async {
    try {
      final restoredSession = await _authService.restoreSession();
      if (restoredSession?.isExpired == true) {
        // Saklanan erişim tokenı yenilenemez; eski oturumla ana ekrana geçmek
        // mağaza isteklerinin sonsuza kadar yükleniyor gibi görünmesine yol açar.
        await _authService.logout();
        _session = null;
        _errorMessage = const ApiException(
          ApiErrorType.unauthorized,
        ).userMessage;
      } else {
        _session = restoredSession;
      }
      _accounts = await _authService.listAccounts();
      _status = _session == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    } catch (_) {
      await _authService.logout();
      _session = null;
      _accounts = const [];
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> openRiotLogin() async {
    _errorMessage = null;
    notifyListeners();
    final opened = await launchUrl(
      Uri.parse(AppConstants.authUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      _errorMessage =
          'Riot giriş sayfası açılamadı. Tarayıcınızı kontrol edip tekrar deneyin.';
      notifyListeners();
    }
  }

  Future<void> handleIncomingLink(Uri uri) async {
    await authenticateFromRedirect(uri.toString());
  }

  Future<void> authenticateFromRedirect(String clipboardValue) async {
    if (_status == AuthStatus.authenticating) return;
    final previousSession = _session;
    _errorMessage = null;
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final tokens = RiotAuthService.parseRedirectUrl(clipboardValue);
      _session = await _authService.completeAuthentication(tokens);
      _accounts = await _authService.listAccounts();
      _status = AuthStatus.signedIn;
    } on ApiException catch (error) {
      _session = previousSession;
      _status = previousSession == null
          ? AuthStatus.signedOut
          : AuthStatus.signedIn;
      _errorMessage = error.userMessage;
    } catch (_) {
      _session = previousSession;
      _status = previousSession == null
          ? AuthStatus.signedOut
          : AuthStatus.signedIn;
      _errorMessage = const ApiException(ApiErrorType.unknown).userMessage;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _session = null;
    _accounts = await _authService.listAccounts();
    _errorMessage = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> expireSession() async {
    await _authService.logout();
    _session = null;
    _accounts = await _authService.listAccounts();
    _errorMessage = const ApiException(ApiErrorType.unauthorized).userMessage;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<bool> selectAccount(String puuid) async {
    if (_status == AuthStatus.authenticating) return false;
    final selected = await _authService.selectAccount(puuid);
    if (selected == null) return false;
    _session = selected;
    _errorMessage = null;
    _status = AuthStatus.signedIn;
    notifyListeners();
    return true;
  }

  Future<void> removeAccount(String puuid) async {
    await _authService.removeAccount(puuid);
    _accounts = await _authService.listAccounts();
    if (_session?.puuid.toLowerCase() == puuid.toLowerCase()) {
      _session = null;
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }
}
