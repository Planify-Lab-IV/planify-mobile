import '../domain/activity_entry.dart';
import '../domain/activity_log_repository.dart';
import '../domain/activity_type.dart';
import '../domain/unread_counts.dart';

class FakeActivityLogRepository implements ActivityLogRepository {
  final Duration delay;
  bool shouldThrowError;
  bool shouldThrowUnreadCountsError;
  bool shouldThrowMarkAsReadError;
  final Map<String, int> _unreadByEvent;
  final Map<String, int> _unreadByGroup;
  final Map<String, String> _groupByEvent;
  final Map<String, List<ActivityEntry>> _activityByEventId;

  FakeActivityLogRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldThrowError = false,
    this.shouldThrowUnreadCountsError = false,
    this.shouldThrowMarkAsReadError = false,
    UnreadCounts? initialUnreadCounts,
    Map<String, String>? groupByEvent,
    Map<String, List<ActivityEntry>>? initialActivity,
  }) : _unreadByEvent = Map.of(
         initialUnreadCounts?.byEvent ?? _defaultUnreadByEvent,
       ),
       _unreadByGroup = Map.of(
         initialUnreadCounts?.byGroup ?? _defaultUnreadByGroup,
       ),
       _groupByEvent = Map.of(groupByEvent ?? _defaultGroupByEvent),
       _activityByEventId = Map<String, List<ActivityEntry>>.from(
         initialActivity ?? _defaultActivity,
       );

  @override
  Future<UnreadCounts> getUnreadCounts() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldThrowUnreadCountsError) {
      throw Exception('Could not load unread counts');
    }
    return UnreadCounts(byEvent: _unreadByEvent, byGroup: _unreadByGroup);
  }

  @override
  Future<void> markEventAsRead(String eventId) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (shouldThrowMarkAsReadError) {
      throw Exception('Could not mark event as read');
    }
    final previousCount = _unreadByEvent[eventId] ?? 0;
    _unreadByEvent[eventId] = 0;
    final groupId = _groupByEvent[eventId];
    if (groupId != null) {
      final remaining = (_unreadByGroup[groupId] ?? 0) - previousCount;
      _unreadByGroup[groupId] = remaining < 0 ? 0 : remaining;
    }
  }

  static const _defaultUnreadByEvent = {
    'evt-123': 5,
    'evt-asado-amigos': 7,
    'evt-fake-demo': 0,
    'evt-almuerzo-familia': 1,
  };
  static const _defaultUnreadByGroup = {
    'grp-amigos': 12,
    'grp-familia': 1,
    'grp-trabajo': 0,
  };
  static const _defaultGroupByEvent = {
    'evt-123': 'grp-amigos',
    'evt-asado-amigos': 'grp-amigos',
    'evt-fake-demo': 'grp-amigos',
    'evt-almuerzo-familia': 'grp-familia',
  };

  @override
  Future<List<ActivityEntry>> listEventActivity(String eventId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (shouldThrowError) {
      throw Exception('Could not load event activity');
    }

    // Permite ver el feed mientras se prueba un evento recién creado, cuyo ID
    // no existe todavía en los datos semilla. `evt-fake-demo` sigue teniendo
    // una entrada explícita vacía para cubrir ese estado de la interfaz.
    final entries = _activityByEventId[eventId] ?? _defaultActivity['evt-123']!;
    return List<ActivityEntry>.unmodifiable(entries);
  }

  static final Map<String, List<ActivityEntry>> _defaultActivity = {
    'evt-123': [
      ActivityEntry(
        id: 'activity-evt-123-1',
        type: ActivityType.scheduleConfirmed,
        actorParticipantId: 'participant-org-evt-123',
        actorUsername: 'Lucía',
        payload: {'startDateTime': '2026-01-10T21:00:00.000Z'},
        createdAt: DateTime.utc(2026, 1, 4, 18, 30),
      ),
      ActivityEntry(
        id: 'activity-evt-123-2',
        type: ActivityType.expenseCreated,
        actorParticipantId: 'participant-member-evt-123',
        actorUsername: 'Ana',
        payload: {'description': 'Bebidas', 'totalAmountCents': 24500},
        createdAt: DateTime.utc(2026, 1, 4, 17),
      ),
      ActivityEntry(
        id: 'activity-evt-123-3',
        type: ActivityType.availabilityUpdated,
        actorParticipantId: 'participant-anon-evt-123',
        actorUsername: 'Juan',
        payload: const {},
        createdAt: DateTime.utc(2026, 1, 4, 16),
      ),
      ActivityEntry(
        id: 'activity-evt-123-4',
        type: ActivityType.taskCreated,
        actorParticipantId: 'participant-member-evt-123',
        actorUsername: 'Ana',
        payload: {'title': 'Comprar carne'},
        createdAt: DateTime.utc(2026, 1, 4, 15),
      ),
      ActivityEntry(
        id: 'activity-evt-123-5',
        type: ActivityType.unknown,
        actorParticipantId: 'participant-org-evt-123',
        actorUsername: 'Lucía',
        payload: {'sourceType': 'participantJoined'},
        createdAt: DateTime.utc(2026, 1, 4, 14),
      ),
    ],
    'evt-cumple-lucas': [
      ActivityEntry(
        id: 'activity-evt-cumple-lucas-1',
        type: ActivityType.taskCreated,
        actorParticipantId: 'participant-org-evt-cumple-lucas',
        actorUsername: 'Lucía',
        payload: {'title': 'Preparar la torta'},
        createdAt: DateTime.utc(2026, 1, 3, 12),
      ),
    ],
    'evt-fake-demo': const <ActivityEntry>[],
  };
}
