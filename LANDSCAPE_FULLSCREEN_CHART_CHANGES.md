# Landscape Fullscreen Chart — Mobile Changes (crmapp → white label port)

## What the feature does

On the **Chart** screen (bottom nav → Chart) a **fullscreen button** sits in the header button row, next to the price-alert bell.

Tapping it opens the same chart (same instance: timeframe, drawings and loaded bars are kept) on a full-screen **landscape** page that covers the bottom nav:

- The page swings in: it starts lying flat, shrunk to the screen width, then turns a quarter clockwise and grows to fill the screen (380ms, easeInOut). After the swing the system bars hide.
- The chart fades in about 300ms later, once the WebView has redrawn.
- On the right is a trade panel. Top to bottom:
  1. Exit button
  2. Symbol button, which slides in a symbol list from the right
  3. Lot `+`
  4. Lot value
  5. Lot `−`
  6. SELL tile (bid)
  7. Spread pill
  8. BUY tile (ask)
- **Back** (system back, swipe, or the exit button) closes the symbol list if it is open. Otherwise it covers the chart, hands the chart back to the portrait screen, then swings out.

SELL / BUY use **exactly the same order logic as portrait** (one-click trading, confirmation, account checks). The lot value is shared with portrait.

## The important part: the device never rotates

The first version rotated the device with `SystemChrome.setPreferredOrientations(landscape)`. That produced a black area (half the screen) for about 250ms, plus a blink, on open and again on close. There were two reasons:

1. Rotating makes Android resize the window. The old frame doesn't cover the new size, so the rest is black. Hiding the system bars right after resizes the window again, which is the blink.
2. The chart is a WebView (platform view). If it turns or resizes while visible, Android paints black wherever it hasn't redrawn yet.

The fix has three rules:

- **The app stays portrait-only.** There are no orientation changes and no `Info.plist` / `AndroidManifest.xml` changes. Keep `android:screenOrientation="portrait"` and the portrait-only `UISupportedInterfaceOrientations`.
- **The landscape page is laid out inside Flutter, turned.** A `RotatedBox(quarterTurns: 1)` plus a `MediaQuery` override that reports the flipped size and turned insets. The page thinks it is on a 740×360 screen.
- **The chart is never on screen while it turns or resizes.** It is moved into the page only after the swing has finished, behind an opaque cover. The cover fades off 300ms later. Closing works the other way round.

### Side effects of not rotating (already handled)

- **Keyboard:** a keyboard would open in portrait, sideways across the page. The landscape lot is therefore display-only and changes only with the `+` / `−` buttons.
- **Dialogs:** dialogs, bottom sheets and `showGeneralDialog` open in portrait, outside the turned page. The symbol picker is therefore built inside the page, as a barrier plus a 300px slide-in panel. It has no search field, because of the keyboard.
- **Toasts:** toasts, snackbars and sheets fired by SELL / BUY (for example the order confirmation) still appear in portrait. **This is a known limitation.**
- **ScreenUtil:** do not use ScreenUtil (`.w/.h/.sp/.r`) inside the landscape page; it scales from the portrait design size. Use plain logical pixels.
- **`IconButton`:** in Material 3, `IconButton` pads itself to 48px. Use fixed-size `InkWell`s, or `tapTargetSize: MaterialTapTargetSize.shrinkWrap`. Otherwise the SELL/BUY tiles overflow on short screens.

## Files

| File | Change |
|---|---|
| `lib/widgets/chart/landscape_chart_page.dart` | **New.** Copy it as is. It is generic and does not depend on crmapp. |
| `test/landscape_chart_page_test.dart` | **New.** Copy it as is (7 widget tests). |
| `lib/screens/home/chart_screen.dart` | Wiring, trade panel, picker content, lot, tiles |

No `Info.plist` or `AndroidManifest.xml` changes.

---

## 1. `landscape_chart_page.dart` (copy as is)

- **`openLandscapeChartPage({context, isOpen, backgroundColor, chartBuilder, panelBuilder, symbolPickerBuilder, overlayBuilder})`**
  - Pushes a non-opaque `PageRouteBuilder` on the **root** navigator, with the swing transition.
  - Swing completed: hide the system bars (`immersiveSticky`), then set `isOpen = true`.
  - Reverse starts: restore the bars (`SystemUiMode.manual` with `SystemUiOverlay.values`).
  - After the route completes: remove the listener, force `isOpen = false` if it is still true, and restore the bars.
  - Guards against a double tap with a `Set` of active notifiers.
- **`LandscapeViewport`** wraps the page in `RotatedBox(quarterTurns: 1)` with a `MediaQuery` override:
  - `size.flipped`
  - `padding`, `viewPadding` and `systemGestureInsets` turned with `EdgeInsets.fromLTRB(i.top, i.right, i.bottom, i.left)`
  - `viewInsets: EdgeInsets.zero`
- **`LandscapeChartPage`** (stateful) lays out a `Row`: the chart slot (`Expanded`) on the left, `panelBuilder(...)` on the right.
  - **Chart slot:** the chart is shown only while `isOpen` is true, with a cover (`AnimatedOpacity`, 250ms, `chartCoverKey`) over it. When `isOpen` becomes true, the cover fades out after a 300ms timer.
  - **Close order:**
    1. The cover fades in.
    2. After 250ms, `isOpen = false`.
    3. After 150ms more, `pop()`, which runs the reverse swing.
  - **`PopScope(canPop: false)`:** back closes the picker if it is open, otherwise it closes the page.
  - **In-page symbol picker:** a `black54` barrier (tap to close) and a 300px right panel (`AnimatedSlide` from `Offset(1, 0)`, 220ms). Both are wrapped in `IgnorePointer` while closed.

---

## 2. `chart_screen.dart`

### 2.1 Import + fields

```dart
import 'package:crm_app/widgets/chart/landscape_chart_page.dart';
```

```dart
// True while the chart lives in the landscape page. The chart is keyed by a
// GlobalKey, so the portrait layout must not build it meanwhile.
final ValueNotifier<bool> _isLandscapeChartOpen = ValueNotifier(false);

// Keeps the same Tenax chart (timeframe, drawings, loaded bars) when it moves
// between the portrait layout and the landscape page.
final GlobalKey _tenaxChartKey = GlobalKey();
```

In `dispose()`: `_isLandscapeChartOpen.dispose();`

### 2.2 Chart key — in `_buildChartArea()`

```dart
child: AppTenaxChart(key: _tenaxChartKey, symbol: displaySymbol),
```

### 2.3 Portrait chart follows the notifier — in `build()`

It **must** be a `ValueListenableBuilder` and not a `setState` check. The page sets `isOpen` from the route's animation listener, so both sides have to rebuild in the same frame. That way the chart is moved, not reloaded.

```dart
child: ValueListenableBuilder<bool>(
  valueListenable: _isLandscapeChartOpen,
  builder:
      (_, isOpen, _) =>
          isOpen ? const SizedBox.shrink() : _buildChartArea(),
),
```

### 2.4 Fullscreen button in the header row

In the row with **Pending Orders** and the **price-alert bell**:

- Wrap Pending Orders in `Expanded` and remove its `width: Get.width / 1.25`.
- Replace the `Spacer()` with `SizedBox(width: 8.w)`.
- After the bell, add:

```dart
SizedBox(width: 8.w),
Semantics(
  button: true,
  label: 'Full screen chart',
  child: GestureDetector(
    onTap: _openLandscapeChart,
    child: Container(
      height: 45.h,
      width: 45.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7.r),
        color: AppColors.cardBackGround,
      ),
      child: Icon(Icons.fullscreen_rounded, color: AppColors.primary),
    ),
  ),
),
```

### 2.5 Open

```dart
// The device never rotates: the page is laid out landscape inside the
// portrait app (see openLandscapeChartPage), so Android never resizes the
// window and the chart WebView never paints black while turning.
void _openLandscapeChart() {
  FocusScope.of(context).unfocus();
  openLandscapeChartPage(
    context: context,
    isOpen: _isLandscapeChartOpen,
    backgroundColor: AppColors.tradeBackgroundCenterColor,
    // The page is not rebuilt by ChartScreen's setState, so symbol switches
    // reach the chart and the panel through the shared notifier.
    chartBuilder:
        (_) => ValueListenableBuilder<String>(
          valueListenable: ChartScreen._selectedSymbolNotifier,
          builder: (_, _, _) => _buildChartArea(),
        ),
    panelBuilder:
        (pageContext, openSymbolPicker) => ValueListenableBuilder<String>(
          valueListenable: ChartScreen._selectedSymbolNotifier,
          builder:
              (_, _, _) =>
                  _buildLandscapeTradePanel(pageContext, openSymbolPicker),
        ),
    symbolPickerBuilder:
        (_, closePicker) => _buildLandscapeSymbolPicker(closePicker),
    overlayBuilder: (_) => _buildNotificationStack(),
  );
}
```

### 2.6 Trade panel

```dart
Widget _buildLandscapeTradePanel(
  BuildContext pageContext,
  VoidCallback openSymbolPicker,
) {
  return Container(
    width: 124,
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    decoration: BoxDecoration(
      color: AppColors.cardBackGround,
      border: Border(
        left: BorderSide(color: AppColors.primary.withOpacity(0.12)),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Exit full screen',
            // maybePop goes through the page's PopScope, so the exit button
            // and system back share the same cover -> hand back -> swing out.
            onPressed: () => Navigator.of(pageContext).maybePop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              Icons.fullscreen_exit_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildLandscapeSymbolSwitch(openSymbolPicker),
        const SizedBox(height: 8),
        _buildLandscapeLotStepper(),
        const SizedBox(height: 10),
        // ChartScreen's own setState does not rebuild this page, so the
        // price stream drives the bid/ask/spread refresh here. Flexible lets
        // the block shrink on short screens instead of overflowing.
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: StreamBuilder<dynamic>(
              stream: chartSocketController.priceStream,
              builder: (_, __) => _buildTradingControls(isLandscape: true),
            ),
          ),
        ),
      ],
    ),
  );
}
```

`_buildLandscapeSymbolSwitch(VoidCallback openSymbolPicker)` is a 34px outlined `InkWell` that shows `_removeSymbolSuffix(selectedSymbol)` (in a `FittedBox`, 13px bold) and a `keyboard_arrow_down` icon. Its `onTap` is `openSymbolPicker`.

### 2.7 Symbol picker content (inside the page)

```dart
Widget _buildLandscapeSymbolPicker(VoidCallback closePicker) {
  return Column(
    children: [
      _buildLandscapePickerHeader(closePicker), // "Symbols" + close IconButton
      Expanded(child: _buildLandscapePickerList(closePicker)),
    ],
  );
}
```

`_buildLandscapePickerList(closePicker)` is an `Obx` over `instrumentsController.instruments`:

- Symbols are de-duplicated by `_removeSymbolSuffix(...).toUpperCase()`.
- While favourites are still loading and the list is empty, it shows a spinner. If the list is empty after that, it shows "No favourite symbols".
- Each row is 48px: a 28px flag (`_buildLandscapeFlag`) and the name at 14px. The current symbol gets a check mark.
- Tapping a row calls `closePicker()`, then `_onSymbolChanged(symbol)`.

**The portrait `_showSymbolSelector()` is unchanged.**

### 2.8 Lot (display-only, +/−)

```dart
void _stepLandscapeVolume(double delta) {
  setState(() {
    volume = double.parse(
      (volume + delta).clamp(_minLot, _maxLot).toStringAsFixed(2),
    );
    _volumeController.text = volume.toStringAsFixed(2);
  });
}

Widget _buildLandscapeLotStepper() {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.tradeBackgroundCenterColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLandscapeLotButton(
          label: 'Increase lot',
          icon: Icons.add_rounded,
          onTap: () => _stepLandscapeVolume(0.01),
        ),
        SizedBox(
          height: 30,
          child: Center(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _volumeController,
              builder:
                  (_, value, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value.text.isEmpty
                          ? volume.toStringAsFixed(2)
                          : value.text,
                      maxLines: 1,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
            ),
          ),
        ),
        _buildLandscapeLotButton(
          label: 'Decrease lot',
          icon: Icons.remove_rounded,
          onTap: () => _stepLandscapeVolume(-0.01),
        ),
      ],
    ),
  );
}

// Fixed 30px InkWell: IconButton pads itself to a 48px tap target.
Widget _buildLandscapeLotButton({
  required String label,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 30,
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    ),
  );
}
```

### 2.9 SELL / BUY tiles + spread pill

- `_buildLandscapeTradeTile({label, price, color})` is a rounded (12) coloured tile with a soft shadow. Its label (11px, letter-spaced) and price (17px, w800) sit inside `FittedBox(scaleDown)`, so they shrink instead of overflowing. It is wrapped in `AnimatedOpacity` on `_isPlacingOrder`.
- `_buildLandscapeSpreadPill(spread)` is a small rounded pill with a primary outline, showing `Spread $spread`.

### 2.10 `_buildTradingControls({bool isLandscape = false})`

The order logic inside the SELL / BUY `GestureDetector`s is **not touched**. Only the layout changes:

- Padding is `EdgeInsets.zero` in landscape.
- `Row(` becomes `Flex(direction: isLandscape ? Axis.vertical : Axis.horizontal,`.
- SELL / BUY `child:` is `isLandscape ? _buildLandscapeTradeTile(...) : <existing portrait button>`.
- The gap between them is `isLandscape ? SizedBox(height: 30) : <existing width gap>`.
- The spread is `if (isLandscape) Align(child: _buildLandscapeSpreadPill(difference)) else <existing badge>`.

---

## Existing members the port depends on

- **State:** `selectedSymbol`, `volume`, `_volumeController`, `_minLot`, `_maxLot`, `_isPlacingOrder`
- **Static notifier:** `ChartScreen._selectedSymbolNotifier`
- **Controllers:** `chartSocketController.priceStream`, `instrumentsController.instruments`, `instrumentsController.isLoadingFavorites`
- **Helpers:** `_buildChartArea()`, `_buildNotificationStack()`, `_onSymbolChanged()`, `_removeSymbolSuffix()`, `_getFlagPath()`, `_checkAssetExists()`
- **Theme:** `AppColors.tradeBackgroundCenterColor`, `cardBackGround`, `primary`, `error`, `success`, `onColoredBackground`, `border`, plus `AppTextStyles.label`, `button` and `input`
- **Widget:** `AppTenaxChart` (bundled Tenax chart)

## Automated tests (`test/landscape_chart_page_test.dart`)

All tests run on a portrait 360×740 view at DPR 1, with `SystemChannels.platform` mocked.

- **Mid-swing:** `isOpen` is false, the chart is not in the page, and it is still on the portrait screen.
- **After the swing:** `isOpen` is true, the chart is in the page, and the cover is at 1. It drops to 0 after 300ms plus the fade. The page sees `MediaQuery.sizeOf == Size(740, 360)`.
- **`+`:** changes the lot text.
- **Exit:** the cover goes back to 1 while `isOpen` is still true. After about 260ms `isOpen` is false and the page is still mounted. After settling, the page is gone and the chart is back in portrait.
- **System back:** closes the symbol picker first and keeps the page open.
- **Double tap:** opens only one page.
- **Landscape sizes:** 740×360 and 800×340 lay out with no exception or overflow.
- **No rotation:** `setPreferredOrientations` is never called with a landscape value.

## Manual check (real Android device, screen recording)

1. Tap fullscreen. → Expected: the page swings in with no black frame, and the chart fades in.
2. Tap `+` / `−`. → Expected: the lot changes and portrait shows the same value.
3. Tap the symbol button and pick a symbol. → Expected: the list slides in, and the chart and prices switch.
4. Press system back while the list is open. → Expected: only the list closes.
5. Tap exit, then reopen and use system back. → Expected: both swing out with no black frame, and the portrait chart is intact.
6. Tap SELL / BUY. → Expected: the order flow works as in portrait. Toasts and sheets appear in portrait (known limitation).
