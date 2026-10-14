import 'package:dio/dio.dart';

import '../domain/debt_settlement.dart';
import '../domain/debt_status.dart';
import '../domain/debts_repository.dart';
import '../domain/event_debt.dart';
import '../domain/event_debts.dart';

class HttpDebtsRepository implements DebtsRepository {
  final Dio dio;

  HttpDebtsRepository({required this.dio});

  @override
  Future<EventDebts> listEventDebts(String eventId) async {
    final path = _eventPath(eventId);
    try {
      final response = await dio.get<dynamic>('$path/debts');
      return _eventDebtsFromResponse(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    } on DebtException {
      rethrow;
    } catch (_) {
      throw const InvalidDebtResponseException();
    }
  }

  @override
  Future<void> settleDebt(String eventId, String debtId) async {
    final path = _eventPath(eventId);
    final normalizedDebtId = _normalizedSegment(debtId);
    try {
      await dio.post<dynamic>('$path/debts/$normalizedDebtId/settle');
    } on DioException catch (error) {
      throw _mapError(error);
    } on DebtException {
      rethrow;
    } catch (_) {
      throw const DebtOperationException();
    }
  }

  @override
  Future<void> settleWithPerson(String personKey) async {
    final normalizedPersonKey = _normalizedSegment(personKey);
    try {
      await dio.post<dynamic>('/me/balance/people/$normalizedPersonKey/settle');
    } on DioException catch (error) {
      throw _mapError(error);
    } on DebtException {
      rethrow;
    } catch (_) {
      throw const DebtOperationException();
    }
  }

  String _eventPath(String eventId) => '/events/${_normalizedSegment(eventId)}';

  String _normalizedSegment(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw const DebtValidationException();
    return Uri.encodeComponent(normalized);
  }

  EventDebts _eventDebtsFromResponse(dynamic data) {
    if (data is! Map || data['debts'] is! List || data['allSettled'] is! bool) {
      throw const InvalidDebtResponseException();
    }

    return EventDebts(
      debts: (data['debts'] as List<dynamic>)
          .map(_eventDebtFromResponse)
          .toList(growable: false),
      allSettled: data['allSettled'] as bool,
    );
  }

  EventDebt _eventDebtFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidDebtResponseException();

    final status = _debtStatus(data['status']);
    final settledAt = _settledAt(data['settledAt'], status);
    final debtor = _participant(data['debtor']);
    final creditor = _participant(data['creditor']);

    return EventDebt(
      id: _requiredString(data, 'id'),
      eventId: _requiredString(data, 'eventId'),
      debtorParticipantId: debtor.participantId,
      debtorName: debtor.username,
      creditorParticipantId: creditor.participantId,
      creditorName: creditor.username,
      amountCents: _positiveInt(data, 'amountCents'),
      status: status,
      settledAt: settledAt,
    );
  }

  _DebtParticipant _participant(dynamic data) {
    if (data is! Map) throw const InvalidDebtResponseException();
    return _DebtParticipant(
      participantId: _requiredString(data, 'participantId'),
      username: _requiredString(data, 'username'),
    );
  }

  String _requiredString(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw const InvalidDebtResponseException();
    }
    return value;
  }

  int _positiveInt(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is! int || value <= 0) {
      throw const InvalidDebtResponseException();
    }
    return value;
  }

  DebtStatus _debtStatus(dynamic value) {
    return switch (value) {
      'pending' => DebtStatus.pending,
      'settled' => DebtStatus.settled,
      _ => throw const InvalidDebtResponseException(),
    };
  }

  DateTime? _settledAt(dynamic value, DebtStatus status) {
    if (status == DebtStatus.pending) {
      if (value != null) throw const InvalidDebtResponseException();
      return null;
    }
    if (value is! String) throw const InvalidDebtResponseException();
    final settledAt = DateTime.tryParse(value);
    if (settledAt == null) throw const InvalidDebtResponseException();
    return settledAt;
  }

  DebtException _mapError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        return const DebtValidationException();
      case 401:
        return const DebtAuthenticationException();
      case 403:
        return const DebtAuthorizationException();
      case 404:
        return const DebtNotFoundException();
      case 409:
        final body = error.response?.data;
        if (body is Map && body['error'] == 'DEBT_ALREADY_SETTLED') {
          return const DebtAlreadySettledException();
        }
        return const DebtOperationException();
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => const DebtNetworkException(),
      _ => const DebtOperationException(),
    };
  }
}

class _DebtParticipant {
  final String participantId;
  final String username;

  const _DebtParticipant({required this.participantId, required this.username});
}
