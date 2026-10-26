import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/models/socket_response.dart';
import 'package:crm_app/models/search_instruments_model.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/services/favorites_storage_service.dart';
import 'package:crm_app/controllers/account_controller.dart';
import 'package:crm_app/controllers/trading_controller.dart';
import 'package:crm_app/controllers/chart_socket_controller.dart';
import 'package:crm_app/services/stream_websocket_service.dart';
import 'package:crm_app/models/mt5_account.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crm_app/utils/message_pack_decoder.dart';
import 'package:crm_app/services/websocket_endpoint_helper.dart';
import 'package:crm_app/services/unified_websocket_service.dart';
import 'package:crm_app/services/market_watch_v2_service.dart';
import 'package:crm_app/services/symbol_details_cache_service.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/utils/android_style_extensions.dart';
import 'package:crm_app/widgets/custom_toast.dart';


class InstrumentsController extends GetxController with WidgetsBindingObserver {
  final RxList<ListElement> allInstruments = <ListElement>[].obs;
  final RxList<ListElement> instruments = <ListElement>[].obs;

  // ✅ PERF: Per-symbol reactive price store (prevents full list rebuilds)
  // Each symbol has its own Rx, so only that row's price widgets update.
  final Map<String, Rx<InstrumentPrice>> _priceBySymbol = {};
  final Map<String, InstrumentPrice> _pendingPriceUpdates = {};
  Timer? _priceFlushTimer;
  bool _userScrolling = false;
  Timer? _scrollIdleTimer;

  Rx<InstrumentPrice> priceRx(String symbol) {
    // Stream ticks arrive as `XAUUSD` while cent accounts render
    // `XAUUSD.cent`; both must share one Rx or the row stays at 0.
    final normalized = MarketWatchV2Service.normalizeSymbol(symbol);
    return _priceBySymbol.putIfAbsent(
      normalized,
      () => InstrumentPrice.empty().obs,
    );
  }

  /// Latest live quote for [symbol] (pending batch first, then flushed Rx),
  /// tolerant of broker suffix / case differences. Null when no tick yet.
  InstrumentPrice? getLivePrice(String symbol) {
    if (symbol.isEmpty) return null;
    final normalized = MarketWatchV2Service.normalizeSymbol(symbol);
    final p1 = _pendingPriceUpdates[normalized] ?? _pendingPriceUpdates[symbol];
    if (p1 != null && p1.bid > 0) return p1;
    final p2 = _priceBySymbol[normalized]?.value ?? _priceBySymbol[symbol]?.value;
    if (p2 != null && p2.bid > 0) return p2;
    for (final entry in _priceBySymbol.entries) {
      if (entry.key.toUpperCase() == normalized ||
          MarketWatchV2Service.normalizeSymbol(entry.key) == normalized) {
        if (entry.value.value.bid > 0) return entry.value.value;
      }
    }
    return null;
  }

  /// Instrument row for [symbol] (watchlist first, then all instruments),
  /// matched suffix-agnostically and overlaid with the latest live quote.
  ListElement? findInstrument(String symbol) {
    if (symbol.isEmpty) return null;
    final cleanSym = symbol.trim().toUpperCase();
    final cleanWithoutDot = cleanSym.contains('.')
        ? cleanSym.substring(0, cleanSym.indexOf('.'))
        : cleanSym;

    bool matches(ListElement e) {
      final eUpper = e.symbol.toUpperCase();
      return eUpper == cleanSym ||
          eUpper == cleanWithoutDot ||
          (eUpper.contains('.') &&
              eUpper.substring(0, eUpper.indexOf('.')) == cleanWithoutDot);
    }

    ListElement? match = instruments.firstWhereOrNull(matches) ??
        allInstruments.firstWhereOrNull(matches);

    final live = getLivePrice(symbol);
    if (live != null && live.bid > 0) {
      if (match != null) {
        return match.copyWith(
          bid: live.bid,
          ask: live.ask,
          spreadDiff: live.spreadDiff,
          digits: live.digits,
        );
      }
      return ListElement(
        symbol: symbol,
        bid: live.bid,
        ask: live.ask,
        spreadDiff: live.spreadDiff,
        digits: live.digits,
        last: 0,
        volume: 0,
        volumeReal: 0,
        logo: '',
      );
    }
    return match;
  }

  double _preserveNonZero(double incoming, double current) {
    if (incoming != 0) return incoming;
    return current != 0 ? current : incoming;
  }

  double? _preserveOptionalNonZero(double? incoming, double current) {
    if (incoming != null && incoming != 0) return incoming;
    return current != 0 ? current : incoming;
  }

  void _applyPriceUpdate(ListElement item) {
    // Queue and batch UI updates to keep scrolling smooth.
    // During reconnect/REST hydrate the backend can send placeholder zero values.
    // Preserve the last non-zero price until a valid new value arrives.
    final current = priceRx(item.symbol).value;
    final newPrice = current.copyWith(
      bid: _preserveNonZero(item.bid, current.bid),
      ask: _preserveNonZero(item.ask, current.ask),
      digits: item.digits,
      spreadDiff: _preserveNonZero(item.spreadDiff, current.spreadDiff),
      dayLow: _preserveOptionalNonZero(item.dayLow, current.dayLow),
      dayHigh: _preserveOptionalNonZero(item.dayHigh, current.dayHigh),
    );
    _pendingPriceUpdates[item.symbol] = newPrice;
    // Also key by normalized symbol so suffixed/case-variant lookups hit.
    final normalized = MarketWatchV2Service.normalizeSymbol(item.symbol);
    _pendingPriceUpdates[normalized] = newPrice;
    _schedulePriceFlush();
  }

  void notifyUserScrollActivity() {
    if (!_userScrolling) {
      _userScrolling = true;
    }
    _scrollIdleTimer?.cancel();
    _scrollIdleTimer = Timer(const Duration(milliseconds: 200), () {
      _userScrolling = false;
      _schedulePriceFlush(flushSoon: true);
    });
  }

  void _schedulePriceFlush({bool flushSoon = false}) {
    if (_userScrolling) return;
    if (_pendingPriceUpdates.isEmpty) return;
    if (_priceFlushTimer?.isActive ?? false) return;
    _priceFlushTimer = Timer(
      flushSoon ? const Duration(milliseconds: 30) : const Duration(milliseconds: 120),
      _flushPendingPrices,
    );
  }

  void _flushPendingPrices() {
    if (_userScrolling) return;
    if (_pendingPriceUpdates.isEmpty) return;
    final batch = Map<String, InstrumentPrice>.from(_pendingPriceUpdates);
    _pendingPriceUpdates.clear();
    for (final e in batch.entries) {
      priceRx(e.key).value = e.value;
    }
  }

  // Track previous filtered instruments symbols to detect structure changes
  Set<String> _previousFilteredSymbols = {};
  final RxString currentFilter =
      'Favorites'.obs; // Default to 'Favorites' instead of 'All'
  final RxString currentSort = 'Default'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxMap<String, List<ListElement>> tradingGroups =
      <String, List<ListElement>>{}.obs;

  // Dynamic filters based on WebSocket categories
  final RxList<String> availableFilters = <String>['Favorites'].obs;

  // Favorites management
  final RxList<String> favoriteInstruments = <String>[].obs;
  final RxBool isLoadingFavorites = true.obs;
  final RxBool hasAttemptedInitialLoad = false.obs;

  // Put your WebSocket URL here
  late WebSocketChannel channel;
  StreamSubscription? _unifiedMwSub;
  StreamSubscription<dynamic>? _marketWatchV2Sub;
  bool _marketWatchV2ListenerBound = false;

  // Connection management
  final RxBool isConnected = false.obs;
  /// True while initial REST hydrate + v2 subscribe runs ([startMarketWatchV2Only]).
  /// Start as true so the very first Instruments frame cannot flash the empty
  /// state before the post-frame hydrate begins.
  final RxBool isHydratingInstrumentCatalog = true.obs;
  final RxBool isReconnecting = false.obs;
  Timer? _reconnectTimer;

  // ✅ FIX: Debounce timer to prevent double getSocketdata calls
  Timer? _socketDataDebounceTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseReconnectDelay = Duration(seconds: 3);
  static const Duration _connectionTimeout = Duration(seconds: 10);
  bool _isConnecting = false; // Guard to prevent concurrent connections
  bool _isInitialSnapshot = true; // Track if we're receiving initial snapshot
  bool _isReconnecting =
      false; // Track if we're in reconnection mode to preserve prices
  bool _loggedFirstMessage = false;
  bool _isClearingData =
      false; // Guard to prevent duplicate clearing operations

  // Unsubscribe/resubscribe state
  Completer<void>? _unsubscribeCompleter;

  // Track current account number to detect account changes
  String? _currentAccountNumber;
  String? _currentWsUrl;

  // Get exponential backoff delay
  Duration _getReconnectDelay() {
    final baseSeconds = _baseReconnectDelay.inSeconds;
    final exponentialSeconds =
        baseSeconds * (1 << (_reconnectAttempts - 1).clamp(0, 4));
    return Duration(seconds: exponentialSeconds.clamp(3, 60)); // Max 60 seconds
  }

  // Check if primary account has trading_server="MT5"
  bool _isMT5Account() {
    try {
      final accountController = Get.find<AccountController>();
      final activeAccount = accountController.activeMT5Account;
      return activeAccount?.tradingServer.toUpperCase() == "MT5";
    } catch (e) {
      print('Error checking MT5 account: $e');
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Add lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);

    // Load favorites from storage (cache shown until the server GET returns)
    _loadFavorites();

    // Force reinitialize with new defaults if needed (for existing users)
    _checkAndUpdateDefaults();

    // Server watchlist is the source of truth; replaces the cached list.
    unawaited(_initialMarketWatchLoad());

    // ✅ FIX: Listen to account changes and update instruments data
    try {
      final accountController = Get.find<AccountController>();
      MT5Account? _lastAccount;

      ever(accountController.activeMT5AccountRx, (MT5Account? account) {
        if (account == null) return;

        // Check if account changed (different account number or type)
        final accountChanged =
            _lastAccount == null ||
            _lastAccount!.metaAccountNumber != account.metaAccountNumber ||
            (_lastAccount!.tradingServer.toUpperCase() !=
                account.tradingServer.toUpperCase());

        if (accountChanged) {
          print(
            '═══════════════════════════════════════════════════════════',
          );
          print(
            '🔄 ACCOUNT CHANGED - InstrumentsController',
          );
          print(
            '   From: ${_lastAccount?.metaAccountNumber ?? "N/A"} (${_lastAccount?.tradingServer ?? "N/A"})',
          );
          print(
            '   To:   ${account.metaAccountNumber} (${account.tradingServer})',
          );
          print(
            '═══════════════════════════════════════════════════════════',
          );

          // Update last account
          _lastAccount = account;

          // On /ws/stream the switch auth frame carries no favorites (old
          // account's symbols must not leak), so subscribe the new account's
          // favorites once the REST catalogue confirms which ones it offers.
          if (FlavorConfig.usesSingleStreamSocket) {
            unawaited(_hydrateAndSubscribeForAccount(account));
          }

          // DO NOT call startWebSocket() here
          // WebSocket reconnection is handled centrally by AccountController.setActiveMT5Account()
          // This listener only tracks _lastAccount for change detection
          print(
            'Instruments: Account change detected, reconnection will be handled by AccountController',
          );
        }
      });
    } catch (e) {
      print('⚠️ InstrumentsController: Error setting up account listener: $e');
    }

    _bindMarketWatchV2DecodedListener();
    if (FlavorConfig.usesSingleStreamSocket) {
      _bindTradeSymbolSubscriptions();
      _bindSymbolUnavailableListener();
      _bindStreamAuthResubscribe();
    }

    // ✅ FIX: DON'T initialize WebSocket automatically - let screen decide when to start
    // WebSocket will only start when:
    // 1. User is logged in (checked in startWebSocket method)
    // 2. Screen explicitly calls startWebSocket()
    // _initializeWebSocket();
  }

  /// Called synchronously from InstrumentsScreen.initState before the first
  /// frame. This prevents the initial empty/no-data widget from flashing while
  /// the post-frame background hydrate is about to start.
  void markInitialScreenOpening() {
    if (allInstruments.isEmpty && !hasAttemptedInitialLoad.value) {
      isHydratingInstrumentCatalog.value = true;
    }
  }

  // Method to start WebSocket when screen becomes visible
  void startWebSocket() async {
    final isLoggedIn = await SecureStorageService.isUserLoggedIn();
    if (!isLoggedIn) {
      if (kDebugMode) {
        print('Instruments: User not logged in, skipping WebSocket start');
      }
      return;
    }

    print('🔌 InstrumentsController: Starting marketwatchv2 (legacy unified WS disabled)');
    _bindMarketWatchV2DecodedListener();
    await startMarketWatchV2Only();
  }

  /// Resume/foreground path: restore only price streaming for current favorites.
  ///
  /// Do NOT call REST hydrate and do NOT assign/clear instrument lists here.
  /// That prevents full-screen refresh when returning from background/another app.
  Future<void> resumePriceStreamOnly({bool forceReconnect = false}) async {
    final isLoggedIn = await SecureStorageService.isUserLoggedIn();
    if (!isLoggedIn) return;

    _isClearingData = false;
    _bindMarketWatchV2DecodedListener();

    try {
      final accountController = Get.find<AccountController>();
      _currentAccountNumber =
          accountController.activeMT5Account?.metaAccountNumber;
    } catch (_) {}

    if (!Get.isRegistered<MarketWatchV2Service>()) {
      isConnected.value = false;
      return;
    }

    final v2 = Get.find<MarketWatchV2Service>();
    final syms =
        favoriteInstruments
            .map(MarketWatchV2Service.normalizeSymbol)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();

    if (forceReconnect) {
      await v2.disconnect();
    }

    if (syms.isNotEmpty) {
      await v2.resumeSubscribeSymbols(syms);
    } else {
      await v2.ensureAuthenticatedConnection();
    }
    isConnected.value = true;
  }

  /// REST snapshot for current favorites + v2 subscribe (replaces legacy `/ws/marketwatch`).
  Future<void> startMarketWatchV2Only() async {
    isHydratingInstrumentCatalog.value = true;
    try {
      try {
        final accountController = Get.find<AccountController>();
        _currentAccountNumber =
            accountController.activeMT5Account?.metaAccountNumber;
      } catch (_) {}

      _bindMarketWatchV2DecodedListener();

      if (!Get.isRegistered<MarketWatchV2Service>()) {
        isConnected.value = false;
        return;
      }

      final v2 = Get.find<MarketWatchV2Service>();
      await hydrateFavoritesFromRest();

      final syms =
          favoriteInstruments
              .map(MarketWatchV2Service.normalizeSymbol)
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();
      if (syms.isNotEmpty) {
        await v2.subscribeSymbols(syms);
      } else {
        await v2.ensureAuthenticatedConnection();
      }
      isConnected.value = true;
    } finally {
      isHydratingInstrumentCatalog.value = false;
      hasAttemptedInitialLoad.value = true;
    }
  }

  Worker? _streamAuthWorker;

  /// After login the account worker, the watchlist load and the socket auth
  /// race each other, so favorites could miss the authenticate frame and never
  /// be subscribed (hot restart worked because the order differs). Re-send
  /// them every time the `/ws/stream` socket authenticates.
  void _bindStreamAuthResubscribe() {
    if (!Get.isRegistered<StreamWebSocketService>()) return;
    final stream = Get.find<StreamWebSocketService>();
    _streamAuthWorker?.dispose();
    _streamAuthWorker = ever<bool>(stream.isAuthenticated, (authenticated) {
      if (!authenticated || isClosed) return;
      print(
        'Instruments: stream authenticated, resubscribing ${_normalizedFavorites().length} favorites',
      );
      unawaited(_subscribeFavoritesForActiveAccount());
    });
    if (stream.isAuthenticated.value) {
      unawaited(_subscribeFavoritesForActiveAccount());
    }
  }

  void _bindMarketWatchV2DecodedListener() {
    if (_marketWatchV2ListenerBound) return;
    if (!Get.isRegistered<MarketWatchV2Service>()) return;
    _marketWatchV2ListenerBound = true;
    _marketWatchV2Sub = Get.find<MarketWatchV2Service>().decodedFrames.listen(
      _onMarketWatchV2Decoded,
    );
  }

  void _onMarketWatchV2Decoded(dynamic decodedData) {
    if (_isClearingData) return;
    try {
      final accountController = Get.find<AccountController>();
      final currentAccount = accountController.activeMT5Account;
      if (currentAccount != null &&
          _currentAccountNumber != null &&
          currentAccount.metaAccountNumber != _currentAccountNumber) {
        return;
      }
    } catch (_) {}

    _processDecodedMarketPayload(decodedData);
  }

  /// Public hook: subscribe or unsubscribe on `marketwatchv2` after favorite changes (Search + Instruments).
  Future<void> syncMarketWatchV2AfterFavoriteChange(
    String displaySymbol, {
    required bool isFavoriteNow,
  }) async {
    if (!Get.isRegistered<MarketWatchV2Service>()) return;
    final sym = MarketWatchV2Service.normalizeSymbol(displaySymbol);
    if (sym.isEmpty) return;
    final v2 = Get.find<MarketWatchV2Service>();
    if (isFavoriteNow) {
      await v2.subscribeSymbols([sym]);
    } else {
      await v2.unsubscribeSymbols([sym]);
    }
  }

  /// Load favorite rows from same REST API as search; bid/ask filled by v2 ticks.
  /// Account switch on /ws/stream: subscribe only the favorites the new
  /// account actually offers (favorites ∩ its REST catalogue).
  Future<void> _hydrateAndSubscribeForAccount(MT5Account account) async {
    _currentAccountNumber = account.metaAccountNumber;
    // Fresh install: onInit ran before login (no token yet), so the server
    // watchlist was never fetched and there were no favorites to subscribe.
    if (!_marketWatchLoaded) {
      final loaded = await _loadMarketWatchFromServer();
      if (loaded && !isClosed) _updateFilteredInstruments();
    }
    await hydrateFavoritesFromRest();

    // A newer switch superseded this one while REST was in flight.
    final active =
        Get.find<AccountController>().activeMT5Account?.metaAccountNumber;
    if (active != account.metaAccountNumber) return;
    if (!Get.isRegistered<MarketWatchV2Service>()) return;

    await _subscribeFavoritesForActiveAccount();
  }

  Set<String> _normalizedFavorites() =>
      favoriteInstruments
          .map(MarketWatchV2Service.normalizeSymbol)
          .where((s) => s.isNotEmpty)
          .toSet();

  /// Symbols that must stay on the stream even outside the watchlist: open
  /// positions + pending orders (Position tab P&L) and the chart's selected
  /// symbol (chart / order screen prices).
  Set<String> _symbolsNeededByTrades() {
    final needed = <String>{};
    if (Get.isRegistered<TradingController>()) {
      final trading = Get.find<TradingController>();
      needed.addAll(
        [...trading.marketPositions, ...trading.pendingPositions].map(
          (p) => MarketWatchV2Service.normalizeSymbol(p.symbol),
        ),
      );
    }
    if (Get.isRegistered<ChartSocketController>()) {
      needed.add(
        MarketWatchV2Service.normalizeSymbol(
          Get.find<ChartSocketController>().currentSymbol.value,
        ),
      );
    }
    needed.remove('');
    return needed;
  }

  final List<Worker> _tradeSymbolWorkers = <Worker>[];

  /// Subscribes symbols of newly opened positions / placed pending orders
  /// that are not in the watchlist, so the Position tab gets live prices.
  void _bindTradeSymbolSubscriptions() {
    if (_tradeSymbolWorkers.isNotEmpty) return;
    if (!Get.isRegistered<TradingController>()) return;
    final trading = Get.find<TradingController>();
    final subscribed = <String>{};

    void onTradesChanged(List<TradePosition> _) {
      if (!Get.isRegistered<MarketWatchV2Service>()) return;
      final current = _symbolsNeededByTrades();
      final added = current.difference(subscribed).toList();
      subscribed
        ..clear()
        ..addAll(current);
      if (added.isEmpty) return;
      Get.find<MarketWatchV2Service>().subscribeSymbols(added);
    }

    _tradeSymbolWorkers.addAll([
      ever<List<TradePosition>>(trading.marketPositionsRx, onTradesChanged),
      ever<List<TradePosition>>(trading.pendingPositionsRx, onTradesChanged),
    ]);
  }

  /// Per-account cache of symbols the engine rejected with
  /// `SYMBOL_NOT_AVAILABLE` (ws-stream-reference §6). Those rows are hidden
  /// for that account only; the server watchlist itself is not changed.
  final Map<String, Set<String>> _unavailableSymbolsByAccount =
      <String, Set<String>>{};
  StreamSubscription<Map<String, dynamic>>? _streamControlSub;

  bool _isUnavailableForActiveAccount(String symbol) {
    final account = _currentAccountNumber;
    if (account == null) return false;
    final unavailable = _unavailableSymbolsByAccount[account];
    if (unavailable == null) return false;
    return unavailable.contains(MarketWatchV2Service.normalizeSymbol(symbol));
  }

  void _bindSymbolUnavailableListener() {
    if (_streamControlSub != null) return;
    if (!Get.isRegistered<StreamWebSocketService>()) return;
    _streamControlSub = Get.find<StreamWebSocketService>().control.listen((
      frame,
    ) {
      if (frame['type'] != 'error' ||
          frame['code'] != 'SYMBOL_NOT_AVAILABLE') {
        return;
      }
      final account = _currentAccountNumber;
      final symbol = MarketWatchV2Service.normalizeSymbol(
        frame['symbol']?.toString() ?? '',
      );
      if (account == null || symbol.isEmpty) return;
      final added = _unavailableSymbolsByAccount
          .putIfAbsent(account, () => <String>{})
          .add(symbol);
      if (added) _updateFilteredInstruments();
    });
  }

  /// Subscribes `favorites ∪ trade symbols` and unsubscribes [staleSymbols]
  /// that nothing on screen needs any more.
  Future<void> _subscribeFavoritesForActiveAccount({
    Set<String> staleSymbols = const <String>{},
  }) async {
    if (!Get.isRegistered<MarketWatchV2Service>()) return;
    final v2 = Get.find<MarketWatchV2Service>();

    // Subscribe the whole server watchlist. The engine itself rejects what
    // this account can't trade (SYMBOL_NOT_AVAILABLE), and those rows are
    // then hidden. Filtering against the local catalogue skipped symbols
    // that were not hydrated yet, so their prices stayed at 0.
    final favorites = _normalizedFavorites();
    final visibleFavorites =
        favorites.where((s) => !_isUnavailableForActiveAccount(s)).toSet();
    final tradeSymbols = _symbolsNeededByTrades();

    final toDrop =
        staleSymbols.difference(favorites).difference(tradeSymbols).toList();
    if (toDrop.isNotEmpty) {
      await v2.unsubscribeSymbols(toDrop);
    }

    final toSubscribe = {...visibleFavorites, ...tradeSymbols}.toList();
    if (toSubscribe.isNotEmpty) {
      await v2.subscribeSymbols(toSubscribe);
    }
  }

  Future<void> hydrateFavoritesFromRest() async {
    try {
      final token = await SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        _isClearingData = false;
        return;
      }

      final accountController = Get.find<AccountController>();
      final raw = accountController.activeMT5Account?.metaAccountNumber;
      final tradingAccount =
          (raw != null && raw.trim().isNotEmpty) ? raw.trim() : '0';

      final response = await ApiService.get(
        endpoint: ApiConstants.getInstrumentsByAccount(tradingAccount),
        token: token,
      );

      if (!response.success || response.data == null) {
        _isClearingData = false;
        return;
      }

      final parsed = SearchInstrumentsResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      final symbols = parsed.data?.symbols;
      if (symbols == null || symbols.isEmpty) {
        allInstruments.clear();
        _updateTradingGroups(allInstruments);
        _updateFilteredInstruments();
        _isClearingData = false;
        return;
      }

      final incoming = <ListElement>[];
      for (final s in symbols) {
        if (s.datafeedSymbol.isNotEmpty) {
          SymbolDetailsCacheService.registerDatafeedSymbol(s.displaySymbol, s.datafeedSymbol);
        }
        if (!isFavorite(s.displaySymbol)) continue;
        final current = priceRx(s.displaySymbol).value;
        incoming.add(
          ListElement(
            symbol: s.displaySymbol,
            digits: s.digits,
            bid: current.bid,
            ask: current.ask,
            spreadDiff: current.spreadDiff,
            last: 0,
            volume: 0,
            volumeReal: 0,
            logo: '',
            category: s.categoryName,
            dayLow: current.dayLow > 0 ? current.dayLow : null,
            dayHigh: current.dayHigh > 0 ? current.dayHigh : null,
          ),
        );
      }

      final existingBySymbol = {
        for (final item in allInstruments) item.symbol: item,
      };
      final merged = <ListElement>[];
      for (final it in incoming) {
        final existing = existingBySymbol[it.symbol];
        if (existing != null) {
          merged.add(
            existing.copyWith(
              digits: it.digits,
              category: it.category,
              bid: it.bid,
              ask: it.ask,
              spreadDiff: it.spreadDiff,
              dayLow: it.dayLow,
              dayHigh: it.dayHigh,
            ),
          );
        } else {
          merged.add(it);
        }
      }

      allInstruments.assignAll(merged);
      for (final it in incoming) {
        _applyPriceUpdate(it);
      }

      _isClearingData = false;
      _isInitialSnapshot = false;

      _updateTradingGroups(allInstruments);
      _updateFilteredInstruments();
    } catch (e) {
      if (kDebugMode) {
        print('InstrumentsController: hydrateFavoritesFromRest error: $e');
      }
    }
  }

  List<dynamic>? _legacyListRowFromTickMap(Map<dynamic, dynamic> raw) {
    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (raw.containsKey(k) && raw[k] != null) return raw[k];
      }
      return null;
    }

    final sym = pick(['symbol', 'Symbol', 's', 'name']);
    if (sym == null) return null;
    final bid = pick(['bid', 'Bid', 'b']);
    final ask = pick(['ask', 'Ask', 'a']);
    if (bid == null && ask == null) return null;

    final spread = pick([
      'spread',
      'spread_points',
      'spreadPoints',
      'SpreadDiff',
      'spread_diff',
    ]);
    final digits = pick(['digits', 'Digits', 'd']);
    final dayHigh = pick(['day_high', 'dayHigh', 'high', 'day_high_price']);
    final dayLow = pick(['day_low', 'dayLow', 'low', 'day_low_price']);
    final category = pick(['category', 'Category', 'group', 'Group']);

    return <dynamic>[
      sym.toString(),
      bid ?? 0,
      ask ?? 0,
      spread ?? 0,
      digits ?? 5,
      dayHigh,
      dayLow,
      category?.toString(),
    ];
  }

  void _processDecodedMarketPayload(dynamic decodedData) {
    if (decodedData is Map) {
      final m = Map<dynamic, dynamic>.from(decodedData);
      final row = _legacyListRowFromTickMap(m);
      if (row != null) {
        _parseSingleInstrument(row);
        return;
      }
      final jsonish = <String, dynamic>{};
      for (final e in decodedData.entries) {
        jsonish[e.key.toString()] = e.value;
      }
      _handleJsonResponse(jsonish);
      return;
    }

    if (decodedData is List && decodedData.isNotEmpty && decodedData[0] is Map) {
      for (final item in decodedData) {
        if (item is! Map) continue;
        final row = _legacyListRowFromTickMap(Map<dynamic, dynamic>.from(item));
        if (row != null) {
          _parseSingleInstrument(row);
        }
      }
      return;
    }

    if (decodedData is List && decodedData.isNotEmpty) {
      if (decodedData[0] is List) {
        _parseNewFormat(decodedData);
      } else if (decodedData[0] is String && decodedData.length >= 5) {
        _parseSingleInstrument(decodedData);
      }
    }
  }

  // Method to stop WebSocket when screen is hidden
  void stopWebSocket() {
    print(
      '═══════════════════════════════════════════════════════════',
    );
    print(
      '🛑 STOPPING WEBSOCKET - InstrumentsController',
    );
    print(
      '   Account: ${_currentAccountNumber ?? "N/A"}',
    );
    print(
      '═══════════════════════════════════════════════════════════',
    );
    
    // ✅ FIX: Cancel unified subscription FIRST to stop data flow
    if (_unifiedMwSub != null) {
      print(
        '   Cancelling unified WebSocket subscription...',
      );
      _unifiedMwSub?.cancel();
      _unifiedMwSub = null;
      isConnected.value = false;
    }
    
    // Lifecycle/navigation stop should not enter the full-reset clearing mode;
    // otherwise marketwatchv2 frames after resume can be blocked. Full clearing
    // is handled by clearInstrumentsData() for actual account switches.
    _isClearingData = false;
    
    // Disconnect direct WebSocket if using it
    _disconnectWebSocket();
    
    print(
      '✅ WebSocket stopped and data flow blocked',
    );
  }

  // Check if we need to update defaults (for existing users)
  Future<void> _checkAndUpdateDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrated = prefs.getBool('migrated_favorites_defaults_v2') ?? false;
      if (migrated) {
        return;
      }

      final currentFavorites =
          await FavoritesStorageService.instance.getFavoriteInstruments();
      // If user has old defaults (USOIL, NAS100, BTCUSD), update to new ones
      if (currentFavorites.contains('USIOL.c') ||
          currentFavorites.contains('NAS100.c') ||
          currentFavorites.contains('BTCUSD.c')) {
        print('🔄 Detected old default favorites, updating to new ones');
        await forceReinitializeDefaults();
      }

      // Set migration flag so we don't wipe custom user favorites on next starts
      await prefs.setBool('migrated_favorites_defaults_v2', true);
    } catch (e) {
      print('Error checking and updating defaults: $e');
    }
  }

  void _initializeWebSocket() async {
    if (FlavorConfig.usesSingleStreamSocket) return;
    if (_isConnecting) {
      print('Instruments: Connection already in progress, skipping');
      return;
    }

    // ✅ FIX: Check authentication before initializing WebSocket
    final isLoggedIn = await SecureStorageService.isUserLoggedIn();
    if (!isLoggedIn) {
      if (kDebugMode) {
        print(
          'Instruments: User not logged in, skipping WebSocket initialization',
        );
      }
      return;
    }

    // Check network connectivity first
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('Instruments: No network connectivity, retrying later...');
        _scheduleReconnect();
        return;
      }
    } catch (e) {
      print('Instruments: Error checking connectivity: $e');
      // Continue anyway - connectivity check might not be available
    }

    try {
      _isConnecting = true;
      _isInitialSnapshot = true; // Reset for new connection

      final accountController = Get.find<AccountController>();
      var activeAccount = accountController.activeMT5Account;

      // ✅ FIX: Fallback to stored primary account from initialization
      if (activeAccount == null) {
        activeAccount = await WebSocketEndpointHelper.getStoredPrimaryAccount();
        if (kDebugMode && activeAccount != null) {
          print(
            'Instruments: Using stored primary account from initialization',
          );
        }
      }

      // ✅ Use centralized endpoint helper
      final wsUrl = WebSocketEndpointHelper.getMarketWatchUrl(activeAccount);
      final accountType = WebSocketEndpointHelper.getAccountType(activeAccount);

      print(
        'Instruments: Endpoint change? prev=${_currentWsUrl ?? "none"} -> new=$wsUrl',
      );
      WebSocketEndpointHelper.logSwitchStep(
        'Instruments connect start',
        url: wsUrl,
      );
      print(
        'Instruments: Connecting to $wsUrl ($accountType account, Account: ${activeAccount?.metaAccountNumber ?? "N/A"}, trading_server: ${activeAccount?.tradingServer ?? "N/A"})',
      );

      // Connect with timeout handling
      channel = await Future<WebSocketChannel>.delayed(
        Duration.zero,
        () => WebSocketChannel.connect(Uri.parse(wsUrl)),
      ).timeout(
        _connectionTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Connection timeout after ${_connectionTimeout.inSeconds}s',
          );
        },
      );

      // Don't set isConnected = true yet - wait for first message or confirmation
      _reconnectAttempts = 0;
      isReconnecting.value = false;
      _currentWsUrl = wsUrl;
      _loggedFirstMessage = false;

      // Update current account number when connecting
      try {
        final accountController = Get.find<AccountController>();
        _currentAccountNumber =
            accountController.activeMT5Account?.metaAccountNumber;
      } catch (e) {
        print('Error updating account number: $e');
      }

      // Listen for data from socket server
      // ✅ PERFORMANCE: Handle both JSON (String) and binary (Uint8List) messages
      channel.stream.listen(
        (message) {
          updateFromJson(message); // Can be String (JSON) or Uint8List (binary)
          // Set connected after receiving first valid message
          if (!isConnected.value) {
            isConnected.value = true;
            print('Instruments: WebSocket connected and receiving data');
          }
          if (!_loggedFirstMessage) {
            _loggedFirstMessage = true;
            WebSocketEndpointHelper.logSwitchStep(
              'Instruments first message',
              url: _currentWsUrl,
            );
          }
        },
        onError: (error) {
          print('Instruments: WebSocket error: $error');
          isConnected.value = false;
          _isConnecting = false;
          _scheduleReconnect();
        },
        onDone: () {
          print('Instruments: WebSocket connection closed');
          isConnected.value = false;
          _isConnecting = false;
          _scheduleReconnect();
        },
      );

      // Request authentication and subscription
      // ✅ PERFORMANCE: Request binary format for improved performance
      getSocketdata();
      _isConnecting = false;
    } catch (e) {
      print('Instruments: Failed to initialize WebSocket: $e');
      isConnected.value = false;
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void getSocketdata() async {
    // Legacy unified `/ws/marketwatch` auth payload — disabled. Use marketwatchv2 instead.
    _socketDataDebounceTimer?.cancel();
    _socketDataDebounceTimer = Timer(const Duration(milliseconds: 120), () async {
      await startMarketWatchV2Only();
    });
  }

  void updateFromJson(dynamic message) {
    try {
      // ✅ PERFORMANCE: Handle both JSON and binary (MessagePack) formats
      // WebSocket can send either String (JSON) or Uint8List (binary)
      dynamic decodedData;

      if (MessagePackDecoder.isBinaryMessage(message)) {
        // Binary MessagePack format - decode it
        if (kDebugMode) {
          final sizeInfo = MessagePackDecoder.getMessageSize(message);
          WebSocketEndpointHelper.logSwitchStep(
            'Instruments first snapshot',
            url: _currentWsUrl,
            payload: {'sizeKB': sizeInfo['sizeKB']},
          );
        }
        decodedData = MessagePackDecoder.decodeBinary(
          message is Uint8List
              ? message
              : Uint8List.fromList(message as List<int>),
        );

        if (decodedData == null) {
          return;
        }
      } else {
        // JSON format - decode as string
        final jsonStr = message is String ? message : message.toString();
        decodedData = jsonDecode(jsonStr);
      }

      // Legacy full-catalog JSON (direct channel only)
      if (decodedData is Map && decodedData['groups'] is List) {
        try {
          final SocketResponse socketResponse = SocketResponse.fromJson(
            Map<String, dynamic>.from(decodedData),
          );

          final List<ListElement> allItems = [];
          final Map<String, List<ListElement>> map = {};
          final Set<String> uniqueCategories = {};

          for (final group in socketResponse.groups) {
            var groupName = group.groupName;

            if (groupName.toLowerCase() == 'fx cross' ||
                groupName.toLowerCase() == 'fxcross') {
              groupName = 'Forex';
            }
            if (groupName.toLowerCase() == 'currency') {
              groupName = 'Forex';
            }

            if (!map.containsKey(groupName)) {
              map[groupName] = [];
            }
            map[groupName]!.addAll(group.list);

            if (groupName.isNotEmpty) {
              uniqueCategories.add(groupName);
            }
          }

          tradingGroups.value = map;

          for (final group in socketResponse.groups) {
            allItems.addAll(group.list);
          }

          _updateInstrumentsList(allItems);

          _updateTradingGroups(allInstruments);

          _updateFilteredInstruments();
        } catch (e) {
          print('Error parsing old format: $e');
        }
        return;
      }

      _processDecodedMarketPayload(decodedData);
    } catch (e, t) {
      print('Error parsing JSON: $e\n $t');
    }
  }

  void _handleJsonResponse(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    // Account group changed on server (e.g. admin changed group): resubscribe to get new spreads/market watch
    // Same behaviour as crmfrontend: unsubscribe then resubscribe with same account so server sends new group data
    if (type == 'group_changed') {
      print(
        '🔄 InstrumentsController: Group changed on server, resubscribing to refresh market watch',
      );
      Future.microtask(() => _onGroupChanged());
      return;
    }

    // Handle unsubscribe confirmation
    if (type == 'marketwatch_left') {
      print('✅ Unsubscribed from market watch');
      if (_unsubscribeCompleter != null &&
          !_unsubscribeCompleter!.isCompleted) {
        _unsubscribeCompleter!.complete();
        _unsubscribeCompleter = null;
      }
      return;
    }

    // Handle STEP 2: Confirmation message (subscribed_pricing)
    // Note: This comes AFTER the initial snapshot (STEP 1)
    if (type == 'subscribed_pricing') {
      final status = data['status']?.toString();
      final pricesCount = data['prices_count'];
      final totalSymbols = data['total_symbols'];
      final tradingAccount = data['trading_account'];
      final isReconnection = data['is_reconnection'] ?? false;

      if (status == 'ok') {
        print('✅ Instruments: Subscribed to pricing');
        print('   Account: $tradingAccount');
        print('   Prices count: $pricesCount / Total symbols: $totalSymbols');
        print('   Is reconnection: $isReconnection');

        // Confirmation received - initial snapshot should have been processed already
        // Next arrays will be real-time updates (STEP 3)
        _isInitialSnapshot = false;

        // ✅ Clear reconnection flag after successful subscription
        if (_isReconnecting) {
          _isReconnecting = false;
          print('✅ Reconnection complete - normal updates resumed');
        }

        // Set connected state after successful subscription
        if (!isConnected.value) {
          isConnected.value = true;
        }
      }
      return;
    }

    // Handle authentication success messages
    if (type == 'marketwatch_joined' ||
        type == 'symbol_joined' ||
        type == 'authenticated') {
      final status = data['status']?.toString();
      final message = data['message']?.toString();

      if (status == 'success') {
        print('✅ WebSocket authenticated: $message');
        if (type == 'marketwatch_joined') {
          print(
            '✅ Subscribed to market watch for account: ${data['trading_account']}',
          );
        } else if (type == 'symbol_joined') {
          print('✅ Subscribed to symbol: ${data['symbol']}');
        }
      }
      return;
    }

    // Handle error responses
    if (type == 'error') {
      final errorMessage = data['message']?.toString() ?? 'Unknown error';
      print('❌ WebSocket error: $errorMessage');
      // Complete unsubscribe completer even on error to avoid hanging
      if (_unsubscribeCompleter != null &&
          !_unsubscribeCompleter!.isCompleted) {
        _unsubscribeCompleter!.complete();
        _unsubscribeCompleter = null;
      }
      return;
    }

    // Handle other JSON responses (if any)
    print('📨 Received JSON response: $data');
  }

  void _parseNewFormat(List decodedData) {
    final List<ListElement> incomingItems = [];

    for (final item in decodedData) {
      final parsed = _parseInstrumentItem(item);
      if (parsed != null) incomingItems.add(parsed);
    }

    // STEP 1: Initial snapshot - replace all instruments
    // STEP 3: Real-time updates - merge/update only changed symbols
    // ✅ FIX: During reconnection, always use merge logic to preserve prices
    if (_isInitialSnapshot && incomingItems.isNotEmpty && !_isReconnecting) {
      // This is the FIRST initial snapshot (not a reconnection) - replace all
      print(
        '═══════════════════════════════════════════════════════════',
      );
      print(
        '📊 INITIAL SNAPSHOT RECEIVED',
      );
      print(
        '   Account: ${_currentAccountNumber ?? "N/A"}',
      );
      print(
        '   Symbols count: ${incomingItems.length}',
      );
      print(
        '   Sample symbols: ${incomingItems.take(5).map((e) => e.symbol).join(", ")}${incomingItems.length > 5 ? "..." : ""}',
      );
      print(
        '═══════════════════════════════════════════════════════════',
      );
      
      // ✅ FIX: Reset clearing flag BEFORE assigning data (allows data processing)
      if (_isClearingData) {
        _isClearingData = false;
        print(
          '✅ Clearing flag reset - data processing enabled',
        );
      }
      
      // ✅ COMPLETE REBUILD: Clear first, then assign new data.
      // Price values are still sanitized through _applyPriceUpdate(), so an
      // initial/reconnect snapshot cannot overwrite previous non-zero prices
      // with placeholder zeros.
      allInstruments.clear();
      allInstruments.assignAll(incomingItems);
      _isInitialSnapshot = false; // Next updates will be real-time

      // Seed reactive prices for all symbols in snapshot.
      for (final it in incomingItems) {
        _applyPriceUpdate(it);
      }
      
      print(
        '✅ Instruments list INSTANTIATED: ${allInstruments.length} total instruments',
      );
      print(
        '   Verified count: ${allInstruments.length == incomingItems.length ? "✅ MATCH" : "❌ MISMATCH"} (expected ${incomingItems.length})',
      );
    } else {
      // Real-time updates: update reactive prices only (no RxList assignAll).
      // Only touch allInstruments/instruments when structure changes (new symbols).
      final existingSymbols = allInstruments.map((e) => e.symbol).toSet();
      bool structureChanged = false;

      for (final newItem in incomingItems) {
        _applyPriceUpdate(newItem);

        if (!existingSymbols.contains(newItem.symbol)) {
          allInstruments.add(newItem);
          existingSymbols.add(newItem.symbol);
          structureChanged = true;
        }
      }

      // ✅ Clear reconnection flag after first successful merge
      if (_isReconnecting) {
        _isReconnecting = false;
        print('✅ Reconnection merge complete - prices preserved');
      }

      // Only update groups/filters when list structure changed.
      if (!structureChanged) {
        return;
      }
    }

    // ✅ Update trading groups and available filters
    _updateTradingGroups(allInstruments);

    // ✅ Apply current filter and sort
    _updateFilteredInstruments();
  }

  void _parseSingleInstrument(List item) {
    final newItem = _parseInstrumentItem(item);
    if (newItem != null) {
      _applyPriceUpdate(newItem);
      // Check if this symbol already exists
      final existingIndex = allInstruments.indexWhere(
        (element) => element.symbol == newItem.symbol,
      );

      if (existingIndex != -1) {
        // Price tick for an existing symbol.
        // ✅ CRITICAL PERF: Do NOT rebuild filtered list here.
        // Prices are displayed via priceRx(symbol), so the UI stays realtime
        // without triggering a full ListView rebuild.
        //
        // Keep structure stable; optionally update metadata if needed,
        // but do not call _updateFilteredInstruments().
        final existing = allInstruments[existingIndex];
        allInstruments[existingIndex] = existing.copyWith(
          // metadata that may change occasionally
          spreadDiff: newItem.spreadDiff,
          digits: newItem.digits,
          category: newItem.category,
          dayHigh: newItem.dayHigh,
          dayLow: newItem.dayLow,
        );
        return;
      } else {
        // ✅ Add brand new instrument
        allInstruments.add(newItem);
      }

      // ✅ Update trading groups and available filters
      _updateTradingGroups(allInstruments);

      // ✅ Apply current filter and sort
      _updateFilteredInstruments();
    }
  }

  ListElement? _parseInstrumentItem(List item) {
    try {
      // New format: [symbol, bid, ask, spread_points, digits, day_high, day_low, category]
      // spread_points is the spread in points (not percentage)
      if (item.length < 5) {
        print(
          "❌ Invalid item format: expected at least 5 elements, got ${item.length}",
        );
        return null;
      }

      final symbol = item[0].toString();
      final bid = double.tryParse(item[1].toString()) ?? 0.0;
      final ask = double.tryParse(item[2].toString()) ?? 0.0;
      final spreadPoints = double.tryParse(item[3].toString()) ?? 0.0;
      final digits = int.tryParse(item[4].toString()) ?? 5;
      // day_high and day_low are at indices 5 and 6
      final dayHigh =
          item.length >= 6 ? (double.tryParse(item[5].toString())) : null;
      final dayLow =
          item.length >= 7 ? (double.tryParse(item[6].toString())) : null;
      final category =
          item.length >= 8
              ? item[7].toString()
              : (item.length >= 6 && dayHigh == null && dayLow == null
                  ? item[5].toString()
                  : null);

      return ListElement(
        symbol: symbol,
        bid: bid,
        ask: ask,
        spreadDiff: spreadPoints, // spread_points from API
        digits: digits,
        last: 0,
        volume: 0,
        volumeReal: 0,
        logo: '',
        category: category,
        dayHigh: dayHigh,
        dayLow: dayLow,
      );
    } catch (e) {
      print("❌ Failed parsing $item — $e");
      return null;
    }
  }

  void _updateTradingGroups(List<ListElement> allItems) {
    final Map<String, List<ListElement>> map = {};
    final Set<String> uniqueCategories = {};

    for (final instrument in allItems) {
      var groupName = instrument.category ?? _inferGroupName(instrument.symbol);

      // Normalize category names
      final lowerName = groupName.toLowerCase();
      if (lowerName == 'fx cross' ||
          lowerName == 'fxcross' ||
          lowerName == 'currency' ||
          lowerName == 'forex') {
        groupName = 'Forex';
      } else if (lowerName == 'metals' || lowerName == 'metal') {
        groupName = 'Metals';
      } else if (lowerName == 'crypto' || lowerName == 'cryptocurrency') {
        groupName = 'Crypto';
      } else if (lowerName == 'indices' || lowerName == 'index') {
        groupName = 'Indices';
      } else if (lowerName == 'commodities' || lowerName == 'commodity') {
        groupName = 'Commodities';
      } else {
        // Capitalize first letter for consistency
        if (groupName.isNotEmpty) {
          groupName =
              groupName[0].toUpperCase() + groupName.substring(1).toLowerCase();
        }
      }

      if (!map.containsKey(groupName)) {
        map[groupName] = [];
      }
      map[groupName]!.add(instrument);

      if (groupName.isNotEmpty) {
        uniqueCategories.add(groupName);
      }
    }

    tradingGroups.value = map;

    // ✅ Update available filters dynamically based on categories
    final List<String> newFilters = ['Favorites'];
    final sortedCategories = uniqueCategories.toList()..sort();
    newFilters.addAll(sortedCategories);
    availableFilters.assignAll(newFilters);
  }

  // Helper method to infer group name from symbol
  String _inferGroupName(String symbol) {
    final upperSymbol = symbol.toUpperCase();

    // Currency pairs
    if (_isCurrencyPair(symbol)) {
      return 'Currency';
    }

    // Metals
    if (upperSymbol.contains('XAU') || upperSymbol.contains('XAG')) {
      return 'Metals';
    }

    // Crypto
    if (upperSymbol.contains('BTC') ||
        upperSymbol.contains('ETH') ||
        upperSymbol.contains('USDT') ||
        upperSymbol.contains('DOGE')) {
      return 'Crypto';
    }

    // Indices
    if (upperSymbol.contains('NAS') ||
        upperSymbol.contains('SPX') ||
        upperSymbol.contains('DOW') ||
        upperSymbol.contains('UK100')) {
      return 'Indices';
    }

    // Commodities
    if (upperSymbol.contains('OIL') || upperSymbol.contains('USIOL')) {
      return 'Commodities';
    }

    return 'Other';
  }

  bool _isCurrencyPair(String symbol) {
    final majorPairs = ['EUR', 'GBP', 'AUD', 'NZD', 'USD', 'CAD', 'CHF', 'JPY'];
    final symbolWithoutSuffix = symbol.removeSuffix();

    int matchCount = 0;
    for (final pair in majorPairs) {
      if (symbolWithoutSuffix.contains(pair)) {
        matchCount++;
      }
    }

    // If it contains 2 major currencies, it's likely a currency pair
    return matchCount >= 2 && symbolWithoutSuffix.length <= 6;
  }

  void _updateInstrumentsList(List<ListElement> newInstruments) {
    // Create a map of existing instruments by symbol for quick lookup
    final Map<String, ListElement> existingInstrumentsMap = {};
    for (final instrument in allInstruments) {
      existingInstrumentsMap[instrument.symbol] = instrument;
    }

    // Update or add instruments - preserve order from WebSocket (newInstruments order)
    final List<ListElement> updatedInstruments = [];
    for (final newInstrument in newInstruments) {
      final existingInstrument = existingInstrumentsMap[newInstrument.symbol];
      if (existingInstrument != null) {
        // Update existing instrument with new price data
        final updatedInstrument = existingInstrument.copyWith(
          bid: newInstrument.bid,
          ask: newInstrument.ask,
          last: newInstrument.last,
          volume: newInstrument.volume,
          volumeReal: newInstrument.volumeReal,
          spreadDiff: newInstrument.spreadDiff,
          category: newInstrument.category,
        );
        updatedInstruments.add(updatedInstrument);
      } else {
        // Add new instrument (preserves WebSocket order)
        updatedInstruments.add(newInstrument);
      }
    }

    // Update the observable list (order is preserved from newInstruments)
    allInstruments.assignAll(updatedInstruments.toSet().toList());
  }

  // Send event with parameters over WebSocket
  void sendEvent(Map<String, dynamic> event) {
    try {
      final unified = Get.find<UnifiedWebSocketService>();
      unified.sendEvent(WebSocketChannelType.marketWatch, event);
    } catch (_) {
      final encoded = jsonEncode(event);
      channel.sink.add(encoded);
    }
  }

  @override
  void onClose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel reconnect timer
    _reconnectTimer?.cancel();
    _unifiedMwSub?.cancel();
    _marketWatchV2Sub?.cancel();
    _marketWatchV2Sub = null;
    _marketWatchV2ListenerBound = false;
    _streamAuthWorker?.dispose();
    _streamAuthWorker = null;
    _streamControlSub?.cancel();
    _streamControlSub = null;
    for (final worker in _tradeSymbolWorkers) {
      worker.dispose();
    }
    _tradeSymbolWorkers.clear();
    _priceFlushTimer?.cancel();
    _scrollIdleTimer?.cancel();

    // Close WebSocket connection when controller disposed
    try {
      channel.sink.close();
    } catch (e) {
      print('Error closing WebSocket: $e');
    }

    super.onClose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Connection state is centrally coordinated by AccountController to prevent race conditions.
    return;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Instruments: Max reconnection attempts reached');
      isReconnecting.value = false;
      return;
    }

    if (isReconnecting.value) return; // Already scheduled

    _reconnectAttempts++;
    isReconnecting.value = true;

    final delay = _getReconnectDelay();
    print(
      'Instruments: Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s (exponential backoff)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!isConnected.value && !_isConnecting) {
        _reconnectWebSocket();
      } else {
        isReconnecting.value = false;
      }
    });
  }

  void _reconnectWebSocket() {
    if (isConnected.value) return;
    if (FlavorConfig.usesSingleStreamSocket) {
      unawaited(resumePriceStreamOnly());
      return;
    }

    print('🔄 Attempting to reconnect WebSocket...');
    isReconnecting.value = true;
    _isReconnecting = true; // ✅ Mark as reconnection to preserve prices

    try {
      _disconnectWebSocket();
      _initializeWebSocket();
    } catch (e) {
      print('Reconnection failed: $e');
      isReconnecting.value = false;
      _isReconnecting = false; // ✅ Clear flag on error
      _scheduleReconnect();
    }
  }

  void disconnectWebSocket() {
    // Guard the `late` field — on pippro/pipze (single stream socket) the
    // legacy channel is never initialised, so touching it throws
    // LateInitializationError on every lifecycle pause.
    if (!isConnected.value && _currentWsUrl == null) {
      return;
    }
    try {
      channel.sink.close();
      isConnected.value = false;
      isReconnecting.value = false;
      _currentWsUrl = null;
      print('InstrumentsController: WebSocket disconnected');
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  void _disconnectWebSocket() {
    disconnectWebSocket();
  }

  void loadInstruments() {
    final currencyInstruments =
        allInstruments
            .where(
              (instrument) =>
                  getGroupNameForSymbol(instrument.symbol) == 'Forex',
            )
            .toList();
    instruments.assignAll(currencyInstruments);
    currentFilter.value = 'Forex';
    searchQuery.value = '';
    isSearching.value = false;
  }

  String getGroupNameForSymbol(String symbol) {
    // First, try to find the symbol in trading groups
    for (final entry in tradingGroups.entries) {
      if (entry.value.any((element) => element.symbol == symbol)) {
        return entry.key;
      }
    }

    // If not found in groups, try to find in allInstruments and use its category
    final instrument = allInstruments.firstWhereOrNull(
      (element) => element.symbol == symbol,
    );

    if (instrument != null && instrument.category != null) {
      var category = instrument.category!;
      // Merge "Fx Cross" into "Forex"
      if (category.toLowerCase() == 'fx cross' ||
          category.toLowerCase() == 'fxcross') {
        return 'Forex';
      }
      return category;
    }

    // Fallback to inferring from symbol
    return _inferGroupName(symbol);
  }

  void searchInstruments(String query) {
    searchQuery.value = query;
    isSearching.value = query.isNotEmpty;
    _updateFilteredInstruments();
  }

  void filterInstruments(String filter) {
    currentFilter.value = filter;
    _updateFilteredInstruments();
  }

  void sortInstruments(String sortBy) {
    currentSort.value = sortBy;
    // Rebuild filtered list so sort reflects immediately for:
    // - current filter (Favorites/category)
    // - current search query
    // Also avoids in-place sorting of RxList (can be a no-op for reactivity).
    _updateFilteredInstruments();
  }

  // Load favorites from storage
  Future<void> _loadFavorites() async {
    try {
      isLoadingFavorites.value = true;
      final favorites =
          await FavoritesStorageService.instance.getFavoriteInstruments();
      favoriteInstruments.assignAll(favorites);
      // print('📱 Loaded ${favorites.length} favorite instruments: $favorites');
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      isLoadingFavorites.value = false;
    }
  }

  // Toggle favorite status for an instrument
  Future<void> toggleFavorite(
    String instrumentSymbol, {
    SearchSymbol? searchSymbol,
    bool hydrateAfterChange = true,
  }) async {
    try {
      // Normalize symbol format - always store with .c suffix for consistency
      final normalizedSymbol =
          instrumentSymbol.endsWith('.c')
              ? instrumentSymbol
              : instrumentSymbol + '.c';

      final adding = !isFavorite(instrumentSymbol);
      final success = await _updateWatchlistOnServer(
        (current) => adding
            ? (current.contains(normalizedSymbol)
                ? current
                : [...current, normalizedSymbol])
            : current
                .where((s) => !_sameSymbol(s, normalizedSymbol))
                .toList(),
      );
      if (success) {
        await _loadFavorites();

        if (searchSymbol != null) {
          _syncSearchSymbolLocally(searchSymbol, isFavoriteNow: isFavorite(instrumentSymbol));
        } else {
          _updateFilteredInstruments();
        }

        if (hydrateAfterChange) {
          await hydrateFavoritesFromRest();
        }
      }
    } catch (e) {
      print('Error toggling favorite for $instrumentSymbol: $e');
    }
  }

  void _syncSearchSymbolLocally(
    SearchSymbol searchSymbol, {
    required bool isFavoriteNow,
  }) {
    final symbol = searchSymbol.displaySymbol;
    final existingIndex = allInstruments.indexWhere(
      (instrument) => instrument.symbol == symbol,
    );

    if (isFavoriteNow) {
      if (existingIndex == -1) {
        final item = ListElement(
          symbol: symbol,
          digits: searchSymbol.digits,
          bid: 0,
          ask: 0,
          spreadDiff: 0,
          last: 0,
          volume: 0,
          volumeReal: 0,
          logo: '',
          category: searchSymbol.categoryName,
        );
        allInstruments.add(item);
        _applyPriceUpdate(item);
      }
    } else if (existingIndex != -1) {
      allInstruments.removeAt(existingIndex);
    }

    _updateTradingGroups(allInstruments);
    _updateFilteredInstruments();
  }

  // Check if an instrument is favorite
  bool isFavorite(String instrumentSymbol) {
    // Check both with and without .c suffix
    final isFav =
        favoriteInstruments.contains(instrumentSymbol) ||
        favoriteInstruments.contains(instrumentSymbol + '.c') ||
        favoriteInstruments.contains(instrumentSymbol.replaceAll('.c', ''));

    // print('🔍 isFavorite check for "$instrumentSymbol": $isFav');
    // print('🔍 Current favorites: $favoriteInstruments');

    return isFav;
  }

  // Add instrument to favorites
  Future<void> addToFavorites(String instrumentSymbol) async {
    try {
      final success = await _updateWatchlistOnServer(
        (current) => current.any((s) => _sameSymbol(s, instrumentSymbol))
            ? current
            : [...current, instrumentSymbol],
      );
      if (success) {
        await _loadFavorites();
        _updateFilteredInstruments();
        await hydrateFavoritesFromRest();
        await syncMarketWatchV2AfterFavoriteChange(
          instrumentSymbol,
          isFavoriteNow: true,
        );
        print('Added $instrumentSymbol to favorites');
      }
    } catch (e) {
      print('Error adding $instrumentSymbol to favorites: $e');
    }
  }

  // Remove instrument from favorites
  Future<void> removeFromFavorites(String instrumentSymbol) async {
    try {
      // Clean symbol variations to ensure thorough removal
      final String cleanSymbol = instrumentSymbol.contains('.') 
          ? instrumentSymbol.substring(0, instrumentSymbol.lastIndexOf('.'))
          : instrumentSymbol;
      
      // Drop locally first so a swiped Dismissible leaves the tree this frame.
      favoriteInstruments.removeWhere((s) => _sameSymbol(s, cleanSymbol));
      _updateFilteredInstruments();

      // Remove all suffix variations (.c / .r) in the full list POSTed.
      final success = await _updateWatchlistOnServer(
        (current) =>
            current.where((s) => !_sameSymbol(s, cleanSymbol)).toList(),
      );
      if (!success) {
        if (!isClosed) {
          await _loadFavorites();
          _updateFilteredInstruments();
        }
        return;
      }

      await _loadFavorites();
      _updateFilteredInstruments();
      await hydrateFavoritesFromRest();
      await syncMarketWatchV2AfterFavoriteChange(
        instrumentSymbol,
        isFavoriteNow: false,
      );
      print('Removed $instrumentSymbol (and variations) from favorites');
    } catch (e) {
      print('Error removing $instrumentSymbol from favorites: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Server watchlist (`user/trade/marketwatch`)
  // GET  -> `{data: [symbols]}`            (current list)
  // POST -> `{symbols: [...]}` full list    (server replaces the whole list)
  // DELETE -> resets to the server default list
  // The local FavoritesStorageService copy is only a cache of the server list.
  // ---------------------------------------------------------------------------

  /// True once the server list was loaded. Until then POSTs are held back,
  /// because a POST replaces the whole server list.
  bool _marketWatchLoaded = false;

  /// Bumped per GET so only the newest GET's result is applied.
  int _marketWatchLoadSeq = 0;

  /// Serializes POSTs so each full list is built from the previous reply.
  Future<void> _watchlistWriteChain = Future<void>.value();

  bool _sameSymbol(String a, String b) =>
      MarketWatchV2Service.normalizeSymbol(a) ==
      MarketWatchV2Service.normalizeSymbol(b);

  /// Startup: GET the server list, then refresh symbols for it. Runs
  /// unawaited from onInit, so it must never throw.
  Future<void> _initialMarketWatchLoad() async {
    try {
      final loaded = await _loadMarketWatchFromServer();
      if (!loaded || isClosed) return;
      _updateFilteredInstruments();
      await hydrateFavoritesFromRest();
      // On a fresh login the local favorites are empty when the screen and
      // account bind subscribe, so nothing reaches /ws/stream. Subscribe the
      // server watchlist now that it has landed.
      if (FlavorConfig.usesSingleStreamSocket && !isClosed) {
        await _subscribeFavoritesForActiveAccount();
      }
    } catch (e) {
      print('Initial marketwatch load failed: $e');
    }
  }

  /// Returns true only when the server list replaced the local favorites.
  Future<bool> _loadMarketWatchFromServer() async {
    final loadSeq = ++_marketWatchLoadSeq;
    final token = await SecureStorageService.getAuthToken();
    if (token == null || token.isEmpty) return false;

    // 3 tries, 300 ms apart, for a flaky network / 429 right after login.
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (isClosed || loadSeq != _marketWatchLoadSeq) return false;
      try {
        final response = await ApiService.get(
          endpoint: ApiConstants.marketWatch,
          token: token,
        );
        if (isClosed || loadSeq != _marketWatchLoadSeq) return false;
        final body = response.data;
        final serverSymbols = body is Map ? body['data'] : null;
        if (!response.success || serverSymbols is! List) continue;

        await _applyServerWatchlist(serverSymbols);
        return true;
      } catch (e) {
        print('Error loading marketwatch from server (try ${attempt + 1}): $e');
      }
    }
    return false;
  }

  /// Queues a full-list POST built by [buildNext] from the last
  /// server-confirmed list. Never throws; completes with true on success.
  Future<bool> _updateWatchlistOnServer(
    List<String> Function(List<String> current) buildNext,
  ) {
    final completer = Completer<bool>();
    _watchlistWriteChain = _watchlistWriteChain.then((_) async {
      var saved = false;
      try {
        if (!isClosed) saved = await _postWatchlist(buildNext);
      } catch (e) {
        print('Marketwatch update error: $e');
      } finally {
        completer.complete(saved);
      }
    });
    return completer.future;
  }

  Future<bool> _postWatchlist(
    List<String> Function(List<String> current) buildNext,
  ) async {
    if (!_marketWatchLoaded) {
      final loaded = await _loadMarketWatchFromServer();
      if (!loaded) {
        CustomToastService.showError(
          message: 'Unable to load watchlist. Please try again.',
        );
        return false;
      }
    }

    final current =
        await FavoritesStorageService.instance.getFavoriteInstruments();
    final next = <String>[];
    for (final s in buildNext(current)) {
      if (s.isNotEmpty && !next.any((e) => _sameSymbol(e, s))) next.add(s);
    }

    final unchanged = next.length == current.length &&
        Iterable<int>.generate(next.length).every((i) => next[i] == current[i]);
    if (unchanged) return true;

    // Always send the complete final list (server replaces it). An empty
    // list is valid — DELETE would instead restore the server default.
    String? errorMessage;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) await Future.delayed(const Duration(seconds: 1));
      try {
        final response = await ApiService.post(
          endpoint: ApiConstants.marketWatch,
          data: {'symbols': next},
        );
        final body = response.data;
        final data = body is Map ? body['data'] : null;
        final serverSymbols = data is Map ? data['symbols'] : null;

        if (response.success && serverSymbols is List) {
          await _applyServerWatchlist(serverSymbols);
          return true;
        }
        errorMessage = response.message;
      } catch (e) {
        print('Marketwatch update failed (try ${attempt + 1}): $e');
      }
    }

    final message = errorMessage ?? '';
    CustomToastService.showError(
      message: message.isNotEmpty
          ? message
          : 'Unable to update watchlist. Please try again.',
    );
    return false;
  }

  /// DELETE wipes the saved list; GET then returns the server default.
  Future<bool> resetMarketWatch() async {
    final response =
        await ApiService.delete(endpoint: ApiConstants.marketWatch);
    if (!response.success) {
      final message = response.message ?? '';
      CustomToastService.showError(
        message: message.isNotEmpty
            ? message
            : 'Unable to reset watchlist. Please try again.',
      );
      return false;
    }
    final loaded = await _loadMarketWatchFromServer();
    if (!loaded) return false;
    _updateFilteredInstruments();
    await hydrateFavoritesFromRest();
    return true;
  }

  /// Caches the server list locally and refreshes the in-memory favorites.
  /// No-op once closed, so a late reply can't overwrite a new user's list.
  Future<void> _applyServerWatchlist(List<dynamic> serverSymbols) async {
    if (isClosed) return;
    final symbols = <String>[];
    for (final e in serverSymbols) {
      final s = e.toString().trim();
      if (s.isNotEmpty && !symbols.any((x) => _sameSymbol(x, s))) {
        symbols.add(s);
      }
    }
    await FavoritesStorageService.instance.saveFavoriteInstruments(symbols);
    _marketWatchLoaded = true;
    await _loadFavorites();
  }

  // Get favorites count
  int get favoritesCount => favoriteInstruments.length;

  // Reset to default favorites (useful for testing or user preference)
  Future<void> resetToDefaultFavorites() async {
    try {
      await FavoritesStorageService.instance.resetToDefaultFavorites();
      await _loadFavorites();
      _updateFilteredInstruments();
      print('Reset to default favorites');
    } catch (e) {
      print('Error resetting to default favorites: $e');
    }
  }

  // Force reinitialize with new defaults (useful when default list changes)
  Future<void> forceReinitializeDefaults() async {
    try {
      await FavoritesStorageService.instance.forceReinitializeDefaults();
      await _loadFavorites();
      _updateFilteredInstruments();
      print('Force reinitialized with new defaults');
    } catch (e) {
      print('Error force reinitializing defaults: $e');
    }
  }

  // Reorder instruments in the list
  Future<void> reorderInstruments(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Update the UI list immediately
    final ListElement item = instruments.removeAt(oldIndex);
    instruments.insert(newIndex, item);

    // If we are viewing favorites, we should persist the new order
    if (currentFilter.value == 'Favorites') {
      try {
        final List<String> currentFavs = List.from(favoriteInstruments);
        final String symbol = currentFavs.removeAt(oldIndex);
        currentFavs.insert(newIndex, symbol);
        
        // Save to persistent storage
        await FavoritesStorageService.instance.saveFavoriteInstruments(currentFavs);
        
        // Update local RxList
        favoriteInstruments.assignAll(currentFavs);
        
        print('Reordered favorites: $currentFavs');
      } catch (e) {
        print('Error persisting reordered favorites: $e');
      }
    }
  }

  void _updateFilteredInstruments() {
    List<ListElement> filteredInstruments = List.from(allInstruments);

    // If searching, ignore category/favorites filter and search across ALL instruments
    if (searchQuery.value.isNotEmpty) {
      // Search across all instruments regardless of current filter
      filteredInstruments =
          filteredInstruments
              .where(
                (instrument) => instrument.symbol.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
              )
              .toList();
    } else {
      // Only apply category/favorites filter when NOT searching
      // Apply category filter
      if (currentFilter.value != 'Favorites') {
        filteredInstruments =
            filteredInstruments
                .where(
                  (instrument) =>
                      getGroupNameForSymbol(instrument.symbol) ==
                      currentFilter.value,
                )
                .toList();
      }

      // Apply favorites filter
      if (currentFilter.value == 'Favorites') {
        filteredInstruments =
            filteredInstruments
                .where((instrument) => isFavorite(instrument.symbol))
                .toList();
      }
    }

    // Apply current sort (preserve sort when filters/search change)
    _applyCurrentSort(filteredInstruments);

    // ✅ PERFORMANCE FIX: Detect if list structure changed (items added/removed)
    // vs just prices updated
    final currentSymbols = filteredInstruments.map((i) => i.symbol).toSet();
    final structureChanged =
        currentSymbols.length != _previousFilteredSymbols.length ||
        !currentSymbols.containsAll(_previousFilteredSymbols) ||
        !_previousFilteredSymbols.containsAll(currentSymbols);

    // Update the filtered list (RxList will trigger reactive updates automatically)
    instruments.assignAll(filteredInstruments);

    // ✅ PERFORMANCE FIX: Only call update() when list structure changes
    // Price updates will be handled reactively by RxList, no need for full GetBuilder rebuild
    if (structureChanged) {
      _previousFilteredSymbols = currentSymbols;
      update(); // Only rebuild when items are added/removed
    }
    // Note: Price updates don't need update() - RxList changes trigger Obx automatically
  }

  // Helper method to apply current sort to instruments list
  void _applyCurrentSort(List<ListElement> instrumentsToSort) {
    switch (currentSort.value) {
      case 'Default':
        // Don't sort - keep original order from WebSocket
        break;
      case 'Symbol A-Z':
        instrumentsToSort.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case 'Symbol Z-A':
        instrumentsToSort.sort((a, b) => b.symbol.compareTo(a.symbol));
        break;
      default:
        // Default: keep original order from WebSocket
        break;
    }
  }

  // Method to refresh socket data when account changes
  void refreshSocketData() {
    print("Refreshing socket data for new account...");

    // Update current account number
    try {
      final accountController = Get.find<AccountController>();
      _currentAccountNumber =
          accountController.activeMT5Account?.metaAccountNumber;
    } catch (e) {
      print('Error updating account number in refreshSocketData: $e');
    }

    // If not connected, try to reconnect first
    if (!isConnected.value) {
      print("Not connected, attempting marketwatchv2 refresh...");
      Future.microtask(() async {
        await startMarketWatchV2Only();
      });
    } else {
      getSocketdata();
    }
  }

  // Clear instruments data (called when account changes)
  // Note: This method is now called AFTER subscription is cancelled in account change handler
  void clearInstrumentsData() {
    // ✅ FIX: Prevent duplicate clearing - only clear once
    if (_isClearingData) {
      print(
        "⚠️ InstrumentsController: Already clearing data, skipping duplicate clear",
      );
      return;
    }

    _isClearingData = true; // Set flag to prevent duplicate clearing and block data processing

    
    print(
      '═══════════════════════════════════════════════════════════',
    );
    print(
      "🗑️ CLEARING INSTRUMENTS DATA - COMPLETE RESET",
    );
    print(
      "   Account: ${_currentAccountNumber ?? "N/A"}",
    );
    print(
      "   Before clear: Total=${allInstruments.length}, Filtered=${instruments.length}",
    );
    print(
      '═══════════════════════════════════════════════════════════',
    );
    
    // ✅ FIX: Cancel unified subscription FIRST to stop old data flow
    // This is critical when called from AccountController (dashboard switch)
    if (_unifiedMwSub != null) {
      print(
        '   Cancelling unified WebSocket subscription to stop old data...',
      );
      _unifiedMwSub?.cancel();
      _unifiedMwSub = null;
      isConnected.value = false;
    }

    isHydratingInstrumentCatalog.value = false;

    // ✅ Clear all data
    allInstruments.clear();
    instruments.clear();
    tradingGroups.clear();
    // Reset filter to 'Favorites' to show favorites from new account
    currentFilter.value = 'Favorites';
    // Clear available filters and rebuild from new account data
    availableFilters.value = ['Favorites'];
    searchQuery.value = '';

    // ✅ Also clear trading data to prevent old positions/orders showing
    try {
      final tradingController = Get.find<TradingController>();
      tradingController.clearAllTradingData();
    } catch (e) {
      print('Error clearing trading data: $e');
    }

    print("✅ InstrumentsController: ALL DATA CLEARED");
    print(
      "   After clear: Total=${allInstruments.length}, Filtered=${instruments.length}",
    );
    
    // ✅ Force UI update to show cleared state
    update();
    
    // Note: _isClearingData flag will be reset when initial snapshot arrives
    // This prevents old data from being processed while clearing
  }

  // Method to manually reconnect (can be called from UI)
  Future<void> manualReconnect() async {
    print("Manual reconnection requested");
    _reconnectAttempts = 0; // Reset attempts for manual reconnect

    // Ensure clean disconnect first
    stopWebSocket();
    await Future.delayed(const Duration(milliseconds: 100));

    // Then reconnect
    if (!isConnected.value && !_isConnecting) {
      _initializeWebSocket();
    }
  }

  /// Called when server sends group_changed (admin changed account's group).
  /// Resubscribes with same account so server sends new group's spread snapshot and market watch.
  Future<void> _onGroupChanged() async {
    String? accountNumber = _currentAccountNumber;
    if (accountNumber == null || accountNumber.isEmpty) {
      try {
        final accountController = Get.find<AccountController>();
        final account = accountController.activeMT5Account;
        accountNumber = account?.metaAccountNumber;
      } catch (_) {}
    }
    if (accountNumber == null || accountNumber.isEmpty) {
      print(
        '⚠️ InstrumentsController: Group changed but no current account, skipping resubscribe',
      );
      return;
    }
    await unsubscribeAndResubscribe(accountNumber);
  }

  // Unsubscribe and resubscribe with new account (keeps socket active)
  Future<void> unsubscribeAndResubscribe(String newAccountNumber) async {
    print(
      '🔄 InstrumentsController: marketwatchv2 resync for account: $newAccountNumber',
    );

    _currentAccountNumber = newAccountNumber;

    final wasMT5 = _isMT5Account();

    try {
      final accountController = Get.find<AccountController>();
      final newAccount = accountController.mt5Accounts.firstWhereOrNull(
        (acc) => acc.metaAccountNumber == newAccountNumber,
      );
      final isNowMT5 = newAccount?.tradingServer.toUpperCase() == "MT5";

      if (wasMT5 != isNowMT5) {
        print(
          '🔄 InstrumentsController: Trading server changed (was MT5: $wasMT5, now MT5: $isNowMT5), resyncing v2',
        );
        stopWebSocket();
        await Future.delayed(const Duration(milliseconds: 150));
        clearInstrumentsData();
        await startMarketWatchV2Only();
        return;
      }
    } catch (e) {
      print('⚠️ InstrumentsController: Error checking trading server: $e');
    }

    if (!isConnected.value) {
      print('⚠️ InstrumentsController: Not connected, initializing marketwatchv2');
      clearInstrumentsData();
      await startMarketWatchV2Only();
      return;
    }

    try {
      if (Get.isRegistered<MarketWatchV2Service>()) {
        await Get.find<MarketWatchV2Service>().disconnect();
      }
      clearInstrumentsData();
      await startMarketWatchV2Only();
      print('✅ InstrumentsController: marketwatchv2 resync complete');
    } catch (e) {
      print('❌ InstrumentsController: Error in unsubscribeAndResubscribe: $e');
      stopWebSocket();
      await Future.delayed(const Duration(milliseconds: 100));
      clearInstrumentsData();
      await startMarketWatchV2Only();
    }
  }
}

class InstrumentPrice {
  final double bid;
  final double ask;
  final int digits;
  final double spreadDiff;
  final double dayLow;
  final double dayHigh;

  const InstrumentPrice({
    required this.bid,
    required this.ask,
    required this.digits,
    required this.spreadDiff,
    required this.dayLow,
    required this.dayHigh,
  });

  factory InstrumentPrice.empty() =>
      const InstrumentPrice(bid: 0.0, ask: 0.0, digits: 5, spreadDiff: 0.0, dayLow: 0.0, dayHigh: 0.0);

  InstrumentPrice copyWith({
    double? bid,
    double? ask,
    int? digits,
    double? spreadDiff,
    double? dayLow,
    double? dayHigh,
  }) {
    return InstrumentPrice(
      bid: bid ?? this.bid,
      ask: ask ?? this.ask,
      digits: digits ?? this.digits,
      spreadDiff: spreadDiff ?? this.spreadDiff,
      dayLow: dayLow ?? this.dayLow,
      dayHigh: dayHigh ?? this.dayHigh,
    );
  }
}
