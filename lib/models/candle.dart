/// Barrel file for the candlestick chart data model.
///
/// Re-exports [Candle] from the `candlesticks` package so other layers of
/// the app can depend on `package:crm_app/models/candle.dart` instead of
/// importing the third-party package directly. This keeps imports stable
/// even if we ever swap charting libraries.
library;

export 'package:candlesticks/candlesticks.dart' show Candle;