import 'package:get/get.dart';
import 'package:crm_app/services/market_watch_v2_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';

/// Maintains the last selected trading symbol.
/// - Defaults to XAUUSD on first use.
/// - Persisted across app restarts via [SecureStorageService]; a restored
///   symbol that is no longer a favourite is reset back to XAUUSD.
class SymbolSelectionService extends GetxService {
  final RxString _lastSymbol = 'XAUUSD'.obs;
  final RxBool _hasUserSelection = false.obs;
  bool _initialized = false;
  bool _isRestoredSelection = false;

  String get currentSymbol => _lastSymbol.value;
  bool get hasUserSelection => _hasUserSelection.value;

  /// True while the current symbol came from storage (previous app session)
  /// and the user has not picked a symbol in this session yet.
  bool get isRestoredSelection => _isRestoredSelection;

  /// Update the current symbol and mark that the user made an explicit choice.
  void setSymbol(String symbol) {
    if (symbol.isEmpty) return;
    _lastSymbol.value = symbol;
    _hasUserSelection.value = true;
    _isRestoredSelection = false;
    // Persist asynchronously; caller doesn't need to await
    SecureStorageService.saveSelectedSymbol(symbol);
  }

  /// Ensure there is a default symbol when nothing has been set yet.
  Future<void> ensureDefault() async {
    await _ensureInitialized();
    if (_lastSymbol.value.isEmpty) {
      _lastSymbol.value = 'XAUUSD';
      SecureStorageService.saveSelectedSymbol(_lastSymbol.value);
    }
  }

  /// Reset back to default and clear the user selection flag.
  void resetToDefault() {
    _lastSymbol.value = 'XAUUSD';
    _hasUserSelection.value = false;
    _isRestoredSelection = false;
    SecureStorageService.saveSelectedSymbol(_lastSymbol.value);
  }

  /// Suffix-agnostic check (`XAUUSD` == `XAUUSD.c` == `XAUUSD.r`).
  static bool isInFavorites(String symbol, List<String> favorites) {
    final normalized = MarketWatchV2Service.normalizeSymbol(symbol);
    return favorites.any(
      (fav) => MarketWatchV2Service.normalizeSymbol(fav) == normalized,
    );
  }

  /// Resets to default when [removedSymbol] is the current selection, so a
  /// symbol removed from favourites is not restored on the next app start.
  void resetIfCurrent(String removedSymbol) {
    if (!isInFavorites(_lastSymbol.value, [removedSymbol])) return;
    resetToDefault();
  }

  /// Resets to default when the symbol restored from the previous session is
  /// no longer in [favorites] (e.g. removed before the app was killed, or
  /// from another device). A symbol picked in this session is left alone.
  Future<void> validateAgainstFavorites(List<String> favorites) async {
    await _ensureInitialized();
    if (!_isRestoredSelection) return;
    final current = _lastSymbol.value;
    if (current.isEmpty || isInFavorites(current, const ['XAUUSD'])) return;
    if (isInFavorites(current, favorites)) return;
    resetToDefault();
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      final savedSymbol = await SecureStorageService.getSelectedSymbol();
      if (savedSymbol != null && savedSymbol.isNotEmpty) {
        _lastSymbol.value = savedSymbol;
        _hasUserSelection.value = true;
        _isRestoredSelection = true;
      } else if (_lastSymbol.value.isEmpty) {
        _lastSymbol.value = 'XAUUSD';
        SecureStorageService.saveSelectedSymbol(_lastSymbol.value);
      }
    } catch (_) {
      // Fallback to default if storage fails
      if (_lastSymbol.value.isEmpty) {
        _lastSymbol.value = 'XAUUSD';
        SecureStorageService.saveSelectedSymbol(_lastSymbol.value);
      }
    } finally {
      _initialized = true;
    }
  }
}

