import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/tasks/data/http_tasks_repository.dart';
import 'package:planify/features/tasks/data/task_exceptions.dart';
import 'package:planify/features/tasks/domain/task_status.dart';

void main() {
  const taskResponse = <String, dynamic>{
    'id': 'task-1',
    'eventId': 'event-1',
    'title': 'Comprar carne',
    'status': 'unassigned',
    'assignedToParticipantId': null,
    'createdByParticipantId': 'participant-ana',
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
  };

  Dio dioResolving(
    dynamic body,
    void Function(RequestOptions options)? inspect,
  ) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          inspect?.call(options);
          handler.resolve(
            Response<dynamic>(requestOptions: options, data: body),
          );
        },
      ),
    );
    return dio;
  }

  Dio dioRejecting(int statusCode) {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: statusCode,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ),
    );
    return dio;
  }

  Dio dioWithNetworkError() {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      ),
    );
    return dio;
  }

  group('HttpTasksRepository.listTasks', () {
    test('executes GET and maps the tasks response', () async {
      RequestOptions? request;
      final repository = HttpTasksRepository(
        dio: dioResolving({
          'tasks': [
            taskResponse,
            {
              ...taskResponse,
              'id': 'task-2',
              'status': 'pending',
              'assignedToParticipantId': 'participant-beto',
            },
            {
              ...taskResponse,
              'id': 'task-3',
              'status': 'completed',
              'assignedToParticipantId': 'participant-beto',
            },
          ],
        }, (options) => request = options),
      );

      final tasks = await repository.listTasks(' event-1 ');

      expect(request?.method, 'GET');
      expect(request?.path, '/events/event-1/tasks');
      expect(tasks, hasLength(3));
      expect(tasks[0].status, TaskStatus.unassigned);
      expect(tasks[0].assignedToParticipantId, isNull);
      expect(tasks[1].status, TaskStatus.pending);
      expect(tasks[1].assignedToParticipantId, 'participant-beto');
      expect(tasks[2].status, TaskStatus.completed);
      expect(tasks[0].createdByParticipantId, 'participant-ana');
    });

    test('rejects a blank event ID before sending a request', () async {
      var requestCount = 0;
      final repository = HttpTasksRepository(
        dio: dioResolving({'tasks': <dynamic>[]}, (_) => requestCount++),
      );

      await expectLater(
        repository.listTasks('   '),
        throwsA(isA<TaskValidationException>()),
      );
      expect(requestCount, 0);
    });

    test('rejects an invalid response structure', () async {
      final repository = HttpTasksRepository(
        dio: dioResolving({'items': <dynamic>[]}, null),
      );

      await expectLater(
        repository.listTasks('event-1'),
        throwsA(isA<InvalidTaskResponseException>()),
      );
    });

    test('rejects an unknown task status', () async {
      final repository = HttpTasksRepository(
        dio: dioResolving({
          'tasks': [
            {...taskResponse, 'status': 'cancelled'},
          ],
        }, null),
      );

      await expectLater(
        repository.listTasks('event-1'),
        throwsA(isA<InvalidTaskResponseException>()),
      );
    });
  });

  group('HttpTasksRepository.createTask', () {
    test('executes POST with the normalized title and maps the task', () async {
      RequestOptions? request;
      final repository = HttpTasksRepository(
        dio: dioResolving(taskResponse, (options) => request = options),
      );

      final task = await repository.createTask(
        ' event-1 ',
        '  Comprar carne  ',
      );

      expect(request?.method, 'POST');
      expect(request?.path, '/events/event-1/tasks');
      expect(request?.data, {'title': 'Comprar carne'});
      expect(task.id, 'task-1');
      expect(task.eventId, 'event-1');
      expect(task.title, 'Comprar carne');
      expect(task.status, TaskStatus.unassigned);
      expect(task.assignedToParticipantId, isNull);
      expect(task.createdByParticipantId, 'participant-ana');
    });

    test('rejects a blank title before sending a request', () async {
      var requestCount = 0;
      final repository = HttpTasksRepository(
        dio: dioResolving(taskResponse, (_) => requestCount++),
      );

      await expectLater(
        repository.createTask('event-1', '   '),
        throwsA(isA<TaskValidationException>()),
      );
      expect(requestCount, 0);
    });
  });

  group('HttpTasksRepository.claimTask', () {
    test(
      'executes POST without a body and validates the updated task',
      () async {
        RequestOptions? request;
        final repository = HttpTasksRepository(
          dio: dioResolving({
            ...taskResponse,
            'status': 'pending',
            'assignedToParticipantId': 'participant-ana',
          }, (options) => request = options),
        );

        await repository.claimTask(' task-1 ');

        expect(request?.method, 'POST');
        expect(request?.path, '/tasks/task-1/claim');
        expect(request?.data, isNull);
      },
    );
  });

  group('HttpTasksRepository.assignTask', () {
    test('executes POST with the normalized participant ID', () async {
      RequestOptions? request;
      final repository = HttpTasksRepository(
        dio: dioResolving({
          ...taskResponse,
          'status': 'pending',
          'assignedToParticipantId': 'participant-beto',
        }, (options) => request = options),
      );

      await repository.assignTask(' task-1 ', ' participant-beto ');

      expect(request?.method, 'POST');
      expect(request?.path, '/tasks/task-1/assign');
      expect(request?.data, {'participantId': 'participant-beto'});
    });

    test('rejects a blank participant ID before sending a request', () async {
      var requestCount = 0;
      final repository = HttpTasksRepository(
        dio: dioResolving(taskResponse, (_) => requestCount++),
      );

      await expectLater(
        repository.assignTask('task-1', '   '),
        throwsA(isA<TaskValidationException>()),
      );
      expect(requestCount, 0);
    });
  });

  group('HttpTasksRepository.completeTask', () {
    test(
      'executes POST without a body and validates the updated task',
      () async {
        RequestOptions? request;
        final repository = HttpTasksRepository(
          dio: dioResolving({
            ...taskResponse,
            'status': 'completed',
            'assignedToParticipantId': 'participant-beto',
          }, (options) => request = options),
        );

        await repository.completeTask(' task-1 ');

        expect(request?.method, 'POST');
        expect(request?.path, '/tasks/task-1/complete');
        expect(request?.data, isNull);
      },
    );
  });

  group('HttpTasksRepository HTTP errors', () {
    test('maps 400 to TaskValidationException', () async {
      final repository = HttpTasksRepository(dio: dioRejecting(400));

      await expectLater(
        repository.createTask('event-1', 'Comprar carne'),
        throwsA(isA<TaskValidationException>()),
      );
    });

    test('maps 401 to TaskAuthorizationException', () async {
      final repository = HttpTasksRepository(dio: dioRejecting(401));

      await expectLater(
        repository.completeTask('task-1'),
        throwsA(isA<TaskAuthorizationException>()),
      );
    });

    test(
      'rejects completion when the backend denies a participant without the task',
      () async {
        final repository = HttpTasksRepository(dio: dioRejecting(403));

        await expectLater(
          repository.completeTask('task-assigned-to-another-participant'),
          throwsA(isA<TaskAuthorizationException>()),
        );
      },
    );

    test(
      'rejects reassignment when the backend denies a non-organizer',
      () async {
        final repository = HttpTasksRepository(dio: dioRejecting(403));

        await expectLater(
          repository.assignTask('task-1', 'participant-beto'),
          throwsA(isA<TaskAuthorizationException>()),
        );
      },
    );

    test('maps 404 to TaskNotFoundException', () async {
      final repository = HttpTasksRepository(dio: dioRejecting(404));

      await expectLater(
        repository.claimTask('task-missing'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('maps a network failure to NetworkTaskException', () async {
      final repository = HttpTasksRepository(dio: dioWithNetworkError());

      await expectLater(
        repository.listTasks('event-1'),
        throwsA(isA<NetworkTaskException>()),
      );
    });

    test('maps other HTTP errors to TaskOperationException', () async {
      final repository = HttpTasksRepository(dio: dioRejecting(500));

      await expectLater(
        repository.assignTask('task-1', 'participant-beto'),
        throwsA(isA<TaskOperationException>()),
      );
    });
  });
}
