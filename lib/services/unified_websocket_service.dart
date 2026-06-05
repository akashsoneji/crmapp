import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:crm_app/models/mt5_account.dart';
import 'package:crm_app/services/websocket_endpoint_helper.dart';

enum WebSocketChannelType {
  marketWatch,
  symbols,
  openPositions,
  pendingOrders,
  account,
  dashboard, // alias for account data feed
  instruments, // alias for market watch feed
  chart, // alias for symbols feed
}

/// Centralized WebSocket manager.
/// Maintains separate channels per type and exposes broadcast streams.
class UnifiedWebSocketService extends GetxService {
  // Connection flags
  final RxBool isMarketWatchConnected = false.obs;
  final RxBool isSymbolsConnected = false.obs;
  final RxBool isOpenPositionsConnected = false.obs;
  final RxBool isPendingOrdersConnected = false.obs;
  final RxBool isAccountConnected = false.obs;

  // Account-switching guard: prevents concurrent switches and WebSocket operations during active switching
  bool _isAccountSwitching = false;
  Completer<void>? _accountSwitchCompleter;

  // Channels
  WebSocketChannel? _marketWatchChannel;
  WebSocketChannel? _symbolsChannel;
  WebSocketChannel? _opChannel;
  WebSocketChannel? _poChannel;
  WebSocketChannel? _accountChannel;

  // Streams
  final _marketWatchCtrl = StreamController<dynamic>.broadcast();
  final _symbolsCtrl = StreamController<dynamic>.broadcast();
  final _opCtrl = StreamController<dynamic>.broadcast();
  final _poCtrl = StreamController<dynamic>.broadcast();
  final _accountCtrl = StreamController<dynamic>.broadcast();

  // Subscriptions
  StreamSubscription? _mwSub;
  StreamSubscription? _symSub;
  StreamSubscription? _opSub;
  StreamSubscription? _poSub;
  StreamSubscription? _accSub;

  MT5Account? _currentAccount;

  @override
  void onClose() {
    _disposeAll();
    super.onClose();
  }

  // Public streams
  Stream<dynamic> marketWatchStream() => _marketWatchCtrl.stream;
  Stream<dynamic> symbolsStream() => _symbolsCtrl.stream;
  Stream<dynamic> openPositionsStream() => _opCtrl.stream;
  Stream<dynamic> pendingOrdersStream() => _poCtrl.stream;
  Stream<dynamic> accountStream() => _accountCtrl.stream;

  /// Ensure a channel is connected for the provided account.
  Future<void> ensureConnected(
    WebSocketChannelType type,
    MT5Account? account,
  ) async {
    _currentAccount = account ?? _currentAccount;
    switch (type) {
      case WebSocketChannelType.marketWatch:
      case WebSocketChannelType.instruments:
        // Legacy `/ws/marketwatch` removed from unified manager — use [MarketWatchV2Service].
        break;
      case WebSocketChannelType.symbols:
      case WebSocketChannelType.chart:
        if (!isSymbolsConnected.value) {
          await _connectSymbols();
        }
        break;
      case WebSocketChannelType.openPositions:
        if (!isOpenPositionsConnected.value) {
          await _connectOpenPositions();
        }
        break;
      case WebSocketChannelType.pendingOrders:
        if (!isPendingOrdersConnected.value) {
          await _connectPendingOrders();
        }
        break;
      case WebSocketChannelType.account:
      case WebSocketChannelType.dashboard:
        if (!isAccountConnected.value) {
          await _connectAccount();
        }
        break;
    }
  }

  Future<void> switchAccount(MT5Account newAccount) async {
    // Prevent concurrent account switches
    if (_isAccountSwitching) {
      // Wait for ongoing switch to complete first
      await _accountSwitchCompleter?.future;
    }
    _isAccountSwitching = true;
    _accountSwitchCompleter = Completer<void>();

    print(
      '═══════════════════════════════════════════════════════════',
    );
    print(
      '🔄 UNIFIED WEBSOCKET: Switching Account (atomic)',
    );
    print(
      '   From: ${_currentAccount?.metaAccountNumber ?? "N/A"}',
    );
    print(
      '   To:   ${newAccount.metaAccountNumber}',
    );
    print(
      '═══════════════════════════════════════════════════════════',
    );

    try {
      // ✅ STEP 1: Cancel ALL subscriptions to immediately stop all data flow
      print('   STEP 1: Cancelling all subscriptions...');
      _mwSub?.cancel();
      _symSub?.cancel();
      _opSub?.cancel();
      _poSub?.cancel();
      _accSub?.cancel();
      _mwSub = _symSub = _opSub = _poSub = _accSub = null;

      // ✅ STEP 2: Close ALL channels synchronously and set flags to false
      print('   STEP 2: Closing all WebSocket channels...');
      _marketWatchChannel?.sink.close();
      _symbolsChannel?.sink.close();
      _opChannel?.sink.close();
      _poChannel?.sink.close();
      _accountChannel?.sink.close();
      _marketWatchChannel = _symbolsChannel = _opChannel = _poChannel = _accountChannel = null;
      isMarketWatchConnected.value = false;
      isSymbolsConnected.value = false;
      isOpenPositionsConnected.value = false;
      isPendingOrdersConnected.value = false;
      isAccountConnected.value = false;

      // ✅ STEP 3: Update account atomically
      _currentAccount = newAccount;
      print('   STEP 3: Account updated in unified service');

      // ✅ STEP 4: Wait for TCP FIN to propagate before reconnecting
      await Future.delayed(const Duration(milliseconds: 100));

      // ✅ STEP 5: Reconnect all channels with new account
      print('   STEP 4: Reconnecting all channels with new account...');
      await _connectAllChannels();

      print(
        '✅ UNIFIED WEBSOCKET: Account switched successfully',
      );
    } finally {
      _isAccountSwitching = false;
      _accountSwitchCompleter?.complete();
      _accountSwitchCompleter = null;
    }
  }

  Future<void> _connectAllChannels() async {
    await Future.wait([
      // Legacy `_connectMarketWatch` intentionally omitted — instruments use `ws/marketwatchv2`
      // via [MarketWatchV2Service]. Restore `_connectMarketWatch()` here if legacy catalog WS is needed again.
      _connectSymbols(),
      _connectOpenPositions(),
      _connectPendingOrders(),
      _connectAccount(),
    ]);
  }

  Future<void> _connectSymbols() async {
    if (_symbolsChannel != null || _isAccountSwitching) return;
    final url = WebSocketEndpointHelper.getSymbolUrl(_currentAccount);
    _symbolsChannel = WebSocketChannel.connect(Uri.parse(url));
    _symSub = _symbolsChannel!.stream.listen(
      _symbolsCtrl.add,
      onDone: () => isSymbolsConnected.value = false,
      onError: (_) => isSymbolsConnected.value = false,
    );
    isSymbolsConnected.value = true;
  }

  Future<void> _connectOpenPositions() async {
    if (_opChannel != null || _isAccountSwitching) return;
    final url = WebSocketEndpointHelper.getOpenPositionsUrl(_currentAccount);
    _opChannel = WebSocketChannel.connect(Uri.parse(url));
    _opSub = _opChannel!.stream.listen(
      _opCtrl.add,
      onDone: () => isOpenPositionsConnected.value = false,
      onError: (_) => isOpenPositionsConnected.value = false,
    );
    isOpenPositionsConnected.value = true;
  }

  Future<void> _connectPendingOrders() async {
    if (_poChannel != null || _isAccountSwitching) return;
    final url = WebSocketEndpointHelper.getPendingOrdersUrl(_currentAccount);
    _poChannel = WebSocketChannel.connect(Uri.parse(url));
    _poSub = _poChannel!.stream.listen(
      _poCtrl.add,
      onDone: () => isPendingOrdersConnected.value = false,
      onError: (_) => isPendingOrdersConnected.value = false,
    );
    isPendingOrdersConnected.value = true;
  }

  Future<void> _connectAccount() async {
    if (_accountChannel != null || _isAccountSwitching) return;
    final url = WebSocketEndpointHelper.getAccountUrl(_currentAccount);
    _accountChannel = WebSocketChannel.connect(Uri.parse(url));
    _accSub = _accountChannel!.stream.listen(
      _accountCtrl.add,
      onDone: () => isAccountConnected.value = false,
      onError: (_) => isAccountConnected.value = false,
    );
    isAccountConnected.value = true;
  }

// Note: _unsubscribeAllChannels, _closeAllConnections, and _closeChannel were removed
// switchAccount() now handles cancellation and closure directly and atomically

  Future<void> sendEvent(
    WebSocketChannelType type,
    Map<String, dynamic> payload,
  ) async {
    final event = jsonEncode(payload);
    switch (type) {
      case WebSocketChannelType.marketWatch:
      case WebSocketChannelType.instruments:
        _marketWatchChannel?.sink.add(event);
        break;
      case WebSocketChannelType.symbols:
      case WebSocketChannelType.chart:
        _symbolsChannel?.sink.add(event);
        break;
      case WebSocketChannelType.openPositions:
        _opChannel?.sink.add(event);
        break;
      case WebSocketChannelType.pendingOrders:
        _poChannel?.sink.add(event);
        break;
      case WebSocketChannelType.account:
      case WebSocketChannelType.dashboard:
        _accountChannel?.sink.add(event);
        break;
    }
  }

  void disconnectAll() {
    print('🔄 UNIFIED WEBSOCKET: Disconnecting all channels');
    _mwSub?.cancel();
    _symSub?.cancel();
    _opSub?.cancel();
    _poSub?.cancel();
    _accSub?.cancel();
    _mwSub = _symSub = _opSub = _poSub = _accSub = null;

    try { _marketWatchChannel?.sink.close(); } catch (_) {}
    try { _symbolsChannel?.sink.close(); } catch (_) {}
    try { _opChannel?.sink.close(); } catch (_) {}
    try { _poChannel?.sink.close(); } catch (_) {}
    try { _accountChannel?.sink.close(); } catch (_) {}
    _marketWatchChannel = _symbolsChannel = _opChannel = _poChannel = _accountChannel = null;

    isMarketWatchConnected.value = false;
    isSymbolsConnected.value = false;
    isOpenPositionsConnected.value = false;
    isPendingOrdersConnected.value = false;
    isAccountConnected.value = false;
  }

  void _disposeAll() {
    _mwSub?.cancel();
    _symSub?.cancel();
    _opSub?.cancel();
    _poSub?.cancel();
    _accSub?.cancel();
    _marketWatchChannel?.sink.close();
    _symbolsChannel?.sink.close();
    _opChannel?.sink.close();
    _poChannel?.sink.close();
    _accountChannel?.sink.close();
    _marketWatchCtrl.close();
    _symbolsCtrl.close();
    _opCtrl.close();
    _poCtrl.close();
    _accountCtrl.close();
  }
}
