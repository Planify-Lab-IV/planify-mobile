import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/events/attendance/controllers/attendance_notifier.dart';
import 'package:planify/features/events/attendance/controllers/attendance_state.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/attendance_status.dart';

void main() {
  group('AttendanceNotifier', () {
    late FakeEventsRepository repository;
    late AttendanceNotifier notifier;

    setUp(() async {
      repository = FakeEventsRepository(delay: Duration.zero);
      notifier = AttendanceNotifier(
        repository: repository,
        eventId: 'evt-123',
        participantId: 'participant-1',
      );
      await notifier.load();
    });

    tearDown(() => notifier.dispose());

    test('loads noResponse when the participant has not responded', () {
      expect(notifier.state.status, AttendanceStatus.noResponse);
      expect(notifier.state.loadStatus, AttendanceLoadStatus.success);
    });

    test('rolls back to noResponse when the first response fails', () async {
      repository.shouldFailAttendanceResponse = true;

      await notifier.respond(AttendanceResponse.confirmed);

      expect(notifier.state.status, AttendanceStatus.noResponse);
      expect(notifier.state.saveStatus, AttendanceSaveStatus.error);
      expect(
        await repository.getAttendance('evt-123', 'participant-1'),
        AttendanceStatus.noResponse,
      );
    });

    test('persists a typed attendance response', () async {
      await notifier.respond(AttendanceResponse.rejected);

      expect(notifier.state.status, AttendanceStatus.rejected);
      expect(notifier.state.saveStatus, AttendanceSaveStatus.success);
      expect(
        await repository.getAttendance('evt-123', 'participant-1'),
        AttendanceStatus.rejected,
      );
    });
  });
}
