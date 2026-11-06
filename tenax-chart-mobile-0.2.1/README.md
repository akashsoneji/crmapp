# Tenax Chart 0.2.1 — Flutter assets

Drop `assets/chart/` into the Flutter app and declare it:

```yaml
flutter:
  assets:
    - assets/chart/
```

Then load it in a WebView:

```dart
InAppWebView(
  initialFile: 'assets/chart/index.html',
  initialSettings: InAppWebViewSettings(
    transparentBackground: true,
    supportZoom: false,
    useHybridComposition: true, // canvas is the point here
  ),
  onWebViewCreated: (c) => c.addJavaScriptHandler(
    handlerName: 'tenaxchart',
    callback: (args) => _onChartMessage(args.first),
  ),
)
```

The app pushes data in with `TenaxChart.receive({...})` and receives what the
trader did on the `tenaxchart` handler. Nothing is applied inside the chart
until the app confirms it — that rule, the message list and the SL/TP lifecycle
are in `docs/flutter.md` (the Flutter wiring, including the server-bars relay)
and `docs/integration.md` (the order model), both in this zip.

Built files only: no source, no maps, no type declarations.
