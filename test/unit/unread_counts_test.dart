import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/activity_log/domain/unread_counts.dart';

void main() {
  test('devuelve los valores recibidos, sin agregar eventos por grupo', () {
    final counts = UnreadCounts(byEvent: {'e': 4}, byGroup: {'g': 12});
    expect(counts.forEvent('e'), 4);
    expect(counts.forGroup('g'), 12);
    expect(counts.forEvent('missing'), 0);
    expect(counts.forGroup('missing'), 0);
  });

  test('conserva snapshots inmutables de ambos mapas', () {
    final events = {'e': 4};
    final groups = {'g': 12};
    final counts = UnreadCounts(byEvent: events, byGroup: groups);
    events['e'] = 0;
    groups['g'] = 0;
    expect(counts.forEvent('e'), 4);
    expect(counts.forGroup('g'), 12);
    expect(() => counts.byEvent['e'] = 0, throwsUnsupportedError);
    expect(() => counts.byGroup['g'] = 0, throwsUnsupportedError);
  });
}
