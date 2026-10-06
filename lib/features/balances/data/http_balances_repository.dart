import 'package:dio/dio.dart';

import '../domain/balance_direction.dart';
import '../domain/balance_summary.dart';
import '../domain/balances_repository.dart';
import '../domain/event_balance_line.dart';
import '../domain/person_balance.dart';
import '../domain/person_balance_detail.dart';
import '../domain/person_balance_status.dart';
import 'balances_exceptions.dart';

class HttpBalancesRepository implements BalancesRepository {
  final Dio dio;

  HttpBalancesRepository({required this.dio});

  @override
  Future<BalanceSummary> getSummary() async {
    try {
      final response = await dio.get<dynamic>('/me/balance');
      return _summaryFromResponse(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    } on BalancesException {
      rethrow;
    } catch (_) {
      throw const InvalidBalancesResponseException();
    }
  }

  @override
  Future<List<PersonBalance>> listPeople() async {
    try {
      final response = await dio.get<dynamic>('/me/balance/people');
      return _peopleFromResponse(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    } on BalancesException {
      rethrow;
    } catch (_) {
      throw const InvalidBalancesResponseException();
    }
  }

  @override
  Future<PersonBalanceDetail> getPersonDetail(String personKey) async {
    final normalizedPersonKey = personKey.trim();
    if (normalizedPersonKey.isEmpty) {
      throw const InvalidBalancesResponseException();
    }

    try {
      final response = await dio.get<dynamic>(
        '/me/balance/people/${Uri.encodeComponent(normalizedPersonKey)}',
      );
      return _personDetailFromResponse(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    } on BalancesException {
      rethrow;
    } catch (_) {
      throw const InvalidBalancesResponseException();
    }
  }

  BalanceSummary _summaryFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidBalancesResponseException();

    return BalanceSummary(
      owedToMeCents: _nonNegativeInt(data, 'owedToMeCents'),
      iOweCents: _nonNegativeInt(data, 'iOweCents'),
    );
  }

  List<PersonBalance> _peopleFromResponse(dynamic data) {
    if (data is! List) throw const InvalidBalancesResponseException();

    return data.map(_personFromResponse).toList(growable: false);
  }

  PersonBalance _personFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidBalancesResponseException();

    return PersonBalance(
      personKey: _requiredString(data, 'personKey'),
      displayName: _requiredString(data, 'displayName'),
      status: _personBalanceStatus(data['status']),
      netCents: _nonNegativeInt(data, 'netCents'),
    );
  }

  PersonBalanceDetail _personDetailFromResponse(dynamic data) {
    if (data is! Map || data['breakdown'] is! List) {
      throw const InvalidBalancesResponseException();
    }

    return PersonBalanceDetail(
      personKey: _requiredString(data, 'personKey'),
      displayName: _requiredString(data, 'displayName'),
      status: _personBalanceStatus(data['status']),
      netCents: _nonNegativeInt(data, 'netCents'),
      breakdown: (data['breakdown'] as List<dynamic>)
          .map(_eventBalanceLineFromResponse)
          .toList(growable: false),
    );
  }

  EventBalanceLine _eventBalanceLineFromResponse(dynamic data) {
    if (data is! Map) throw const InvalidBalancesResponseException();

    return EventBalanceLine(
      eventId: _requiredString(data, 'eventId'),
      eventName: _requiredString(data, 'eventName'),
      amountCents: _nonNegativeInt(data, 'amountCents'),
      direction: _balanceDirection(data['direction']),
    );
  }

  String _requiredString(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw const InvalidBalancesResponseException();
    }
    return value;
  }

  int _nonNegativeInt(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is! int || value < 0) {
      throw const InvalidBalancesResponseException();
    }
    return value;
  }

  PersonBalanceStatus _personBalanceStatus(dynamic value) {
    return switch (value) {
      'pay' => PersonBalanceStatus.pay,
      'pending' => PersonBalanceStatus.pending,
      'settled' => PersonBalanceStatus.settled,
      _ => throw const InvalidBalancesResponseException(),
    };
  }

  BalanceDirection _balanceDirection(dynamic value) {
    return switch (value) {
      'i_owe' => BalanceDirection.iOwe,
      'owed_to_me' => BalanceDirection.owedToMe,
      _ => throw const InvalidBalancesResponseException(),
    };
  }

  BalancesException _mapError(DioException error) {
    if (error.response?.statusCode == 401) {
      return const AuthenticationBalancesException();
    }
    if (_isNetworkError(error)) {
      return const NetworkBalancesException();
    }
    return const InvalidBalancesResponseException();
  }

  bool _isNetworkError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
