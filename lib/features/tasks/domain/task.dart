import 'task_status.dart';

// Datos inmutables de una tarea perteneciente a un evento.
class Task {
  final String id;
  final String eventId;
  final String title;
  final TaskStatus status;
  final String? assignedToParticipantId;
  final String createdByParticipantId;

  const Task({
    required this.id,
    required this.eventId,
    required this.title,
    required this.status,
    required this.assignedToParticipantId,
    required this.createdByParticipantId,
  });

  Task copyWith({
    String? id,
    String? eventId,
    String? title,
    TaskStatus? status,
    String? assignedToParticipantId,
    String? createdByParticipantId,
  }) {
    return Task(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      status: status ?? this.status,
      assignedToParticipantId:
          assignedToParticipantId ?? this.assignedToParticipantId,
      createdByParticipantId:
          createdByParticipantId ?? this.createdByParticipantId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventId == other.eventId &&
          title == other.title &&
          status == other.status &&
          assignedToParticipantId == other.assignedToParticipantId &&
          createdByParticipantId == other.createdByParticipantId;

  @override
  int get hashCode =>
      id.hashCode ^
      eventId.hashCode ^
      title.hashCode ^
      status.hashCode ^
      assignedToParticipantId.hashCode ^
      createdByParticipantId.hashCode;

  @override
  String toString() {
    return 'Task(id: $id, eventId: $eventId, title: $title, status: $status, assignedToParticipantId: $assignedToParticipantId, createdByParticipantId: $createdByParticipantId)';
  }
}
