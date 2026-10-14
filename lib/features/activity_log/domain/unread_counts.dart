class UnreadCounts {
  final Map<String, int> byEvent;
  final Map<String, int> byGroup;

  UnreadCounts({
    required Map<String, int> byEvent,
    required Map<String, int> byGroup,
  }) : byEvent = Map.unmodifiable(byEvent),
       byGroup = Map.unmodifiable(byGroup);

  int forEvent(String eventId) => byEvent[eventId] ?? 0;

  int forGroup(String groupId) => byGroup[groupId] ?? 0;
}
