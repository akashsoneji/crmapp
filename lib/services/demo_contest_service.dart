import '../constants/api_const.dart';
import '../models/demo_contest/contest_winner_model.dart';
import '../models/demo_contest/demo_contest_enrollment_model.dart';
import '../models/demo_contest/demo_contest_model.dart';
import '../models/demo_contest/leaderboard_entry_model.dart';
import '../models/demo_contest/my_contest_entry_model.dart';
import '../models/demo_contest/demo_contest_my_stats_model.dart';
import '../services/api_service.dart';

/// Real HTTP-backed service for the Demo Contest module.
///
/// Each method calls the backend via [ApiService.get] and maps the JSON
/// response into the shared Dart model classes. The public API surface
/// mirrors the old mock service so the controller needs no changes.
class DemoContestService {
  DemoContestService._internal();
  static final DemoContestService instance = DemoContestService._internal();

  /// All published contests (open, live, upcoming, ended).
  Future<List<DemoContest>> fetchContests() async {
    final response = await ApiService.get(
      endpoint: ApiConstants.demoContestContests,
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to load contests');
    }

    final rawList = response.data is List
        ? response.data as List
        : (response.data['data'] as List? ?? <dynamic>[]);

    return rawList
        .map((e) => DemoContest.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Contests the user has joined (accepted or active entries).
  Future<List<DemoContest>> fetchFeaturedContests() async {
    final all = await fetchContests();
    return all
        .where((c) => c.acceptingEntries || c.isLive)
        .toList(growable: false);
  }

  /// Single contest by id — fetched from the same list endpoint and
  /// filtered locally since the backend returns a flat array.
  Future<DemoContest?> fetchContestById(String id) async {
    final all = await fetchContests();
    return all.firstWhereOrNull((c) => c.id == id);
  }

  /// Top-N leaderboard for a contest.
  Future<List<LeaderboardEntry>> fetchLeaderboard(
    String contestId, {
    int limit = 100,
  }) async {
    final body = await _get(
      ApiConstants.demoContestLeaderboard(contestId),
      'Failed to load leaderboard',
    );
    return _list(body['data'])
        .map((e) => LeaderboardEntry.fromJson(e))
        .take(limit)
        .toList(growable: false);
  }

  /// Top-10 subset of the leaderboard.
  Future<List<LeaderboardEntry>> fetchTopLeaderboard(
    String contestId, {
    int limit = 10,
  }) async {
    return fetchLeaderboard(contestId, limit: limit);
  }

  /// The authenticated user's contest entries, sorted newest first.
  Future<List<MyContestEntry>> fetchMyEntries() async {
    final response = await ApiService.get(
      endpoint: ApiConstants.demoContestContests,
      queryParameters: {'my_entries': '1'},
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to load your entries');
    }

    final rawList = response.data is List
        ? response.data as List
        : (response.data['data'] as List? ?? <dynamic>[]);

    final entries = rawList
        .map((e) => MyContestEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    entries.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
    return entries;
  }

  /// Entry for a specific contest, or null if the user hasn't joined.
  Future<MyContestEntry?> fetchMyEntryForContest(String contestId) async {
    final all = await fetchMyEntries();
    return all.firstWhereOrNull((e) => e.contestId == contestId);
  }

  /// User's own stats for a given contest.
  Future<DemoContestMyStats?> fetchMyStats(String contestId) async {
    final response = await ApiService.get(
      endpoint: ApiConstants.demoContestMyStats,
      queryParameters: {'contest_id': contestId},
    );

    if (!response.success || response.data == null) {
      return null;
    }

    return DemoContestMyStats.fromJson(
      response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {'status': false},
    );
  }

  Future<DemoContestEnrollPreview> enrollPreview(String contestId) async {
    final body = await _post(
      ApiConstants.demoContestEnrollPreview(contestId),
      null,
      'Failed to check enrollment',
    );
    return DemoContestEnrollPreview.fromJson(_map(body['data']));
  }

  Future<List<DemoContestStep>> fetchSteps(String contestId) async {
    final body = await _get(
      ApiConstants.demoContestSteps(contestId),
      'Failed to load enrollment steps',
    );
    return _list(body['data'])
        .map((e) => DemoContestStep.fromJson(e))
        .toList(growable: false);
  }

  Future<void> clickStep(String stepId) async {
    await _post(
      ApiConstants.demoContestStepClick(stepId),
      null,
      'Failed to complete step',
    );
  }

  Future<DemoContestTerms> fetchTerms(String contestId) async {
    final body = await _get(
      ApiConstants.demoContestTerms(contestId),
      'Failed to load terms',
    );
    return DemoContestTerms(
      enabled: body['enabled'] == true,
      content: body['content']?.toString() ?? '',
    );
  }

  /// Creates the contest MT5 account. Returns the backend success message.
  Future<String> enroll(String contestId, {required bool termsAccepted}) async {
    final body = await _post(
      ApiConstants.demoContestEnroll(contestId),
      {'terms_accepted': termsAccepted},
      'Failed to join contest',
    );
    return body['message']?.toString() ?? '';
  }

  /// Submits a prize claim. Returns the backend success message.
  Future<String> claim(String contestId, {String? realAccountNumber}) async {
    final body = await _post(
      ApiConstants.demoContestClaim,
      {
        'contest_id': int.tryParse(contestId) ?? contestId,
        if (realAccountNumber != null && realAccountNumber.isNotEmpty)
          'real_account_number': realAccountNumber,
      },
      'Failed to submit claim',
    );
    return body['message']?.toString() ?? '';
  }

  Future<List<DemoContestTrade>> fetchTradingHistory(String contestId) async {
    final body = await _get(
      ApiConstants.demoContestTradingHistory(contestId),
      'Failed to load trading history',
    );
    return _list(body['data'])
        .map((e) => DemoContestTrade.fromJson(e))
        .toList(growable: false);
  }

  Future<DemoContestRuleViolations> fetchRuleViolations(
    String contestId,
  ) async {
    final body = await _get(
      ApiConstants.demoContestRuleViolations(contestId),
      'Failed to load rule violations',
    );
    return DemoContestRuleViolations.fromJson(_map(body['data']));
  }

  /// Past winners (global leaderboard summary).
  Future<List<ContestWinner>> fetchWinners({int limit = 25}) async {
    final response = await ApiService.get(
      endpoint: ApiConstants.demoContestContests,
      queryParameters: {'winners': '1', 'limit': '$limit'},
    );

    if (!response.success || response.data == null) {
      return <ContestWinner>[];
    }

    final rawList = response.data is List
        ? response.data as List
        : (response.data['data'] as List? ?? <dynamic>[]);

    return rawList
        .map((e) => ContestWinner.fromJson(e as Map<String, dynamic>))
        .take(limit)
        .toList(growable: false);
  }

  // ───────────────────────────── Helpers ─────────────────────────────

  Future<Map<String, dynamic>> _get(String endpoint, String fallback) async {
    final response = await ApiService.get(endpoint: endpoint);
    return _bodyOrThrow(response, fallback);
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic>? data,
    String fallback,
  ) async {
    final response = await ApiService.post(endpoint: endpoint, data: data);
    return _bodyOrThrow(response, fallback);
  }

  /// These APIs report business errors as `status: false` + `message`.
  Map<String, dynamic> _bodyOrThrow(ApiResponse response, String fallback) {
    final body = _map(response.data);
    final message = body['message']?.toString();
    if (!response.success || body['status'] == false) {
      throw Exception(
        (message != null && message.isNotEmpty)
            ? message
            : (response.message ?? fallback),
      );
    }
    return body;
  }

  Map<String, dynamic> _map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}

// ───────────────────────────── Compatibility ─────────────────────────────

extension _IterableFirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
