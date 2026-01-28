# IB Clients Screen - API Flow Implementation

## Overview
This document explains the API flow implementation for the IB Clients screen (`my_clients_screen.dart`).

## API Flow

### Initial Page Load (Master IB View)
When the page first loads (no sub-IB selected), the following 4 APIs are called:

1. **GET** `/api/user/ib/stats?_t={timestamp}`
   - Returns: IB statistics (total clients, deposits, withdrawals, etc.)
   - Used for: Statistics cards at the top

2. **GET** `/api/user/ib/clients?_t={timestamp}`
   - Returns: List of all clients (including sub-IBs)
   - Used for: Client List tab

3. **GET** `/api/user/ib/sub-ibs?_t={timestamp}`
   - Returns: List of all sub-IBs
   - Used for: IB List tab

4. **GET** `/api/user/ib/trade-history?_t={timestamp}`
   - Returns: Trade history for all clients
   - Used for: Trade History tab

### When Sub-IB is Clicked
When a user clicks on a sub-IB (using the arrow button), the following 4 APIs are called with the sub-IB's ID:

5. **GET** `/api/user/ib/sub-ib-stats/{id}?_t={timestamp}`
   - Returns: Statistics for the selected sub-IB
   - Used for: Statistics cards (sub-IB specific stats)

6. **GET** `/api/user/ib/sub-ib-sub-ibs/{id}?_t={timestamp}`
   - Returns: List of sub-IBs under the selected sub-IB
   - Used for: IB List tab (nested sub-IBs)

7. **GET** `/api/user/ib/clients?sub_ib_id={id}&_t={timestamp}`
   - Returns: List of clients under the selected sub-IB
   - Used for: Client List tab (clients under this sub-IB)

8. **GET** `/api/user/ib/trade-history?sub_ib_id={id}&_t={timestamp}`
   - Returns: Trade history for the selected sub-IB's clients
   - Used for: Trade History tab (filtered by sub-IB)

## Implementation Details

### Key Features

1. **Data Clearing**: Before loading new data, all existing data is cleared to prevent showing stale data
2. **Sequential Loading**: APIs are called one by one to ensure proper data consistency
3. **Loading States**: Loading indicator is shown while data is being fetched
4. **Hierarchy Navigation**: Users can navigate back to parent IB using breadcrumb navigation
5. **Refresh Support**: Pull-to-refresh reloads all data for the current view

### Code Structure

```dart
Future<void> _loadMyClientsData({int? subIbId}) async {
  // Clear old data
  ibController.ibClients.clear();
  ibController.ibSubIBs.clear();
  ibController.ibTradeHistory.clear();
  ibController.ibStats.value = null;

  // Set loading state
  ibController.isLoading.value = true;

  if (subIbId == null) {
    // Load Master IB data (APIs 1-4)
    await ibController.getIBStats(showLoading: false);
    await ibController.getIBClients(showLoading: false);
    await ibController.getIBSubIBs(showLoading: false);
    await ibController.getIBTradeHistory(showLoading: false);
  } else {
    // Load Sub-IB data (APIs 5-8)
    await ibController.getIBStats(subIbId: subIbId, showLoading: false);
    await ibController.getIBSubIBs(subIbId: subIbId, showLoading: false);
    await ibController.getIBClients(subIbId: subIbId, showLoading: false);
    await ibController.getIBTradeHistory(subIbId: subIbId, showLoading: false);
  }

  // Clear loading state
  ibController.isLoading.value = false;
}
```

### UI Components

1. **Hierarchy Breadcrumb**: Shows navigation path (Master IB → Sub-IB → Sub-IB's Sub-IB)
2. **Statistics Grid**: 2x2 grid showing key metrics
3. **Tabs**: Three tabs for Client List, IB List, and Trade History
4. **Search Bar**: Filter clients/sub-IBs/trades by name or email
5. **Expandable Cards**: Each item can be expanded to show detailed information

### Mobile Optimization

- Responsive design using `flutter_screenutil`
- Pull-to-refresh support
- Smooth animations and transitions
- Loading states for better UX
- Error handling with retry option

## Testing

To test the implementation:

1. Open the IB Clients screen
2. Verify all 4 initial APIs are called
3. Click on a sub-IB (if available)
4. Verify all 4 sub-IB APIs are called with the correct ID
5. Navigate back to Master IB
6. Verify data is refreshed correctly
7. Test pull-to-refresh functionality
8. Test search functionality across all tabs

## Notes

- All API calls include a timestamp parameter (`_t`) to prevent caching
- Data is cleared before each load to ensure fresh data
- Loading states are managed properly to show/hide loading indicators
- Error handling is implemented with user-friendly messages
