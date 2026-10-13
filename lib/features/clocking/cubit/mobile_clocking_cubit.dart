import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../authentication/model/authentication_result.dart';
import '../../authentication/model/mobile_device.dart';
import '../../authentication/model/mobile_device_identity.dart';
import '../../authentication/model/mobile_user.dart';
import '../../authentication/repository/authentication_repository.dart';
import '../../authentication/service/authentication_service.dart';
import '../../authentication/service/mobile_api_service.dart';
import '../model/attendance_history_record.dart';
import '../model/clocking_record.dart';
import '../model/mobile_attendance_context.dart';
import '../model/mobile_holiday_status.dart';
import '../repository/mobile_clocking_repository.dart';
import 'mobile_clocking_state.dart';

class MobileClockingCubit extends Cubit<MobileClockingState> {
  MobileClockingCubit(
    this._repository,
    this._user,
    this._device,
    this._identity, {
    AuthenticationRepository? localAuthentication,
  })  : _localAuthentication = localAuthentication ??
            AuthenticationRepository(AuthenticationService()),
        super(MobileClockingState());

  final MobileClockingRepository _repository;
  final MobileUser _user;
  final MobileDevice _device;
  final MobileDeviceIdentity _identity;
  final AuthenticationRepository _localAuthentication;
  bool _operationInProgress = false;

  Future<void> initialize({required bool isOnline}) async {
    emit(
      MobileClockingState(
        isLoading: true,
        isOnline: isOnline,
        isAccountActive: _user.isAccountActive,
        isOnLeave: _user.isOnLeave,
      ),
    );
    final errors = <String>[];
    var records = const <ClockingRecord>[];
    MobileAttendanceContext? attendanceContext;
    var history = const <AttendanceHistoryRecord>[];
    MobileHolidayStatus? holidayStatus;
    var requiresSyncAuthentication = false;

    try {
      records = await _repository.loadRecords(_user.id);
    } catch (error) {
      errors.add(
        'Unable to read saved clocking records: ${_messageFor(error)}',
      );
    }
    try {
      attendanceContext = isOnline
          ? await _repository.refreshContext(
              userId: _user.id,
              identity: _identity,
            )
          : await _repository.loadContext(_user.id);
    } catch (error) {
      errors.add('Unable to load attendance settings: ${_messageFor(error)}');
      requiresSyncAuthentication =
          _isAuthenticationRequired(error) &&
          records.any((record) => record.syncStatus == 'pending');
    }
    try {
      history = await _repository.loadAttendanceHistory(_user.id);
    } catch (error) {
      errors.add(
        'Unable to read saved attendance history: ${_messageFor(error)}',
      );
    }
    try {
      holidayStatus = await _repository.loadHolidayStatus(_user.id);
    } catch (error) {
      errors.add('Unable to read saved holiday status: ${_messageFor(error)}');
    }

    if (attendanceContext == null && !isOnline) {
      errors.add(
        'Connect once to load your assigned station before offline clocking.',
      );
    }
    emit(
      MobileClockingState(
        context: attendanceContext,
        records: records,
        history: history,
        holidayStatus: holidayStatus,
        isHolidayStatusLoaded: !isOnline && holidayStatus != null,
        isOnline: isOnline,
        isAccountActive: _user.isAccountActive,
        isOnLeave: _user.isOnLeave,
        requiresSyncAuthentication: requiresSyncAuthentication,
        errorMessage: errors.isEmpty ? null : errors.join('\n'),
      ),
    );
    if (isOnline) {
      if (state.context != null) await synchronizePending();
      await _refreshDashboardData();
    }
    await refreshLocation();
  }

  Future<void> refreshLocation({bool promptIfDisabled = false}) async {
    final currentContext = state.context;
    if (currentContext == null) return;
    try {
      final pos = await _repository.ensureLocationAndGetPosition(
        promptIfDisabled: promptIfDisabled,
      );
      if (pos == null) return;
      final distance = _repository.calculateDistanceMeters(
        pos.latitude,
        pos.longitude,
        currentContext.stationLatitude,
        currentContext.stationLongitude,
      );
      final isWithin = distance <= currentContext.radiusMeters;
      emit(
        state.copyWith(
          userLatitude: pos.latitude,
          userLongitude: pos.longitude,
          distanceMeters: distance,
          isWithinGeofence: isWithin,
        ),
      );
    } catch (_) {}
  }

  Future<void> updateConnectivity(bool isOnline) async {
    if (isClosed || state.isOnline == isOnline) return;
    emit(
      state.copyWith(
        isOnline: isOnline,
        clearError: true,
        clearContext: isOnline,
        isHolidayStatusLoaded: isOnline ? false : null,
        clearHolidayStatus: isOnline,
      ),
    );
    if (isOnline) {
      await synchronizePending(refreshContext: true);
      await _refreshDashboardData();
    } else {
      try {
        final context = await _repository.loadContext(_user.id);
        final history = await _repository.loadAttendanceHistory(_user.id);
        final holidayStatus = await _repository.loadHolidayStatus(_user.id);
        emit(
          state.copyWith(
            context: context,
            history: history,
            holidayStatus: holidayStatus,
            isHolidayStatusLoaded: holidayStatus != null,
          ),
        );
      } catch (error) {
        emit(
          state.copyWith(
            errorMessage:
                'Unable to load saved offline data: ${_messageFor(error)}',
          ),
        );
      }
    }
    await refreshLocation();
  }

  Future<void> clock() async {
    if (_operationInProgress || !state.canClock) return;
    if (state.isOnline && state.pendingCount > 0) {
      await synchronizePending();
      if (state.pendingCount > 0) {
        emit(
          state.copyWith(
            errorMessage: state.errorMessage ??
                'Pending attendance must synchronize before the next clock action.',
          ),
        );
        return;
      }
    }

    final localResult = await _localAuthentication.authenticate();
    if (localResult != AuthenticationResult.authenticated) {
      emit(
        state.copyWith(
          errorMessage:
              'user authentication is required',
        ),
      );
      return;
    }

    _operationInProgress = true;
    final action = state.nextAction!;
    emit(state.copyWith(isClocking: true, clearError: true));

    try {
      final context = state.context!;
      final record = await _repository.createClockingRecord(
        userId: _user.id,
        deviceId: _device.id,
        identity: _identity,
        context: context,
        action: action,
      );
      final records = [...state.records, record];
      emit(
        state.copyWith(
          records: records,
          isClocking: state.isOnline,
          lastActionMessage: state.isOnline
              ? 'Clocking recorded. Sending to KMFRI...'
              : 'Clocking saved securely. It will sync when you are online.',
          clearError: true,
        ),
      );

      if (state.isOnline) {
        try {
          await _synchronizeRecord(record);
        } on _NetworkUnavailable {
          emit(
            state.copyWith(
              isClocking: false,
              errorMessage: 'Sync is unavailable. Your attendance is saved and will retry automatically.',
            ),
          );
        } on MobileApiException catch (error) {
          if (_isAuthenticationRequired(error)) {
            emit(
              state.copyWith(
                isClocking: false,
                requiresSyncAuthentication: true,
                errorMessage:
                    'Authentication is required to synchronize attendance.',
              ),
            );
            return;
          }
          await _markRejected(record, error.message);
          emit(
            state.copyWith(
              isClocking: false,
              errorMessage: 'Attendance was not accepted: ${error.message}',
            ),
          );
        }
        if (record.syncStatus != 'rejected' && state.pendingCount == 0) {
          try {
            await _refreshContext();
            await _refreshHistory();
          } catch (error) {
            emit(
              state.copyWith(
                clearContext: true,
                errorMessage:
                    'Attendance synchronized, but status refresh failed: ${_messageFor(error)}',
              ),
            );
          }
        }
        emit(state.copyWith(isClocking: false));
      }
    } catch (error) {
      emit(state.copyWith(isClocking: false, errorMessage: _messageFor(error)));
    } finally {
      _operationInProgress = false;
    }
  }

  Future<void> synchronizePending({bool refreshContext = false}) async {
    if (_operationInProgress || !state.isOnline || state.isSyncing) return;
    _operationInProgress = true;
    emit(state.copyWith(isSyncing: true, clearError: true));
    try {
      if (refreshContext || state.context == null) {
        await _refreshContext();
      }

      final pendingRecords =
          state.records
              .where((record) => record.syncStatus == 'pending')
              .toList()
            ..sort((left, right) {
              final leftTime = left.createdAt ?? left.time;
              final rightTime = right.createdAt ?? right.time;
              return leftTime.compareTo(rightTime);
            });

      for (final record in pendingRecords) {
        try {
          await _synchronizeRecord(record);
        } on _NetworkUnavailable {
          emit(
            state.copyWith(
              isSyncing: false,
              errorMessage: 'Sync is unavailable. Your attendance is saved and will retry automatically.',
            ),
          );
          return;
        } on MobileApiException catch (error) {
          if (_isAuthenticationRequired(error)) {
            emit(
              state.copyWith(
                isSyncing: false,
                requiresSyncAuthentication: true,
                errorMessage:
                    'Authentication is required to synchronize attendance.',
              ),
            );
            return;
          }
          await _markRejected(record, error.message);
          emit(
            state.copyWith(
              isSyncing: false,
              errorMessage:
                  'A saved attendance event was not accepted: ${error.message}',
            ),
          );
          return;
        }
      }

      if (pendingRecords.isNotEmpty) {
        await _refreshContext();
        emit(
          state.copyWith(
            isSyncing: false,
            lastActionMessage: 'All pending attendance synchronized.',
            clearError: true,
          ),
        );
      } else {
        emit(state.copyWith(isSyncing: false, clearError: true));
      }
      if (pendingRecords.isNotEmpty) await _refreshHistory();
      await _repository.retainRecentHistory(_user.id);
    } on MobileApiException catch (error) {
      if (_isAuthenticationRequired(error) && state.pendingCount > 0) {
        emit(
          state.copyWith(
            isSyncing: false,
            clearContext: true,
            requiresSyncAuthentication: true,
            errorMessage:
                'Authentication is required to synchronize attendance.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            isSyncing: false,
            clearContext: true,
            errorMessage: 'Synchronization will retry: ${_messageFor(error)}',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          isSyncing: false,
          clearContext: true,
          errorMessage: 'Synchronization will retry: ${_messageFor(error)}',
        ),
      );
    } finally {
      _operationInProgress = false;
    }
  }

  Future<String?> authenticateAndSynchronize(String password) async {
    if (_operationInProgress || !state.isOnline) {
      return 'Connect to the internet before authenticating.';
    }
    _operationInProgress = true;
    emit(state.copyWith(isSyncing: true, clearError: true));
    String? authenticationError;
    try {
      await _repository.reauthenticateForSynchronization(
        userId: _user.id,
        deviceId: _device.id,
        identity: _identity,
        password: password,
      );
      emit(
        state.copyWith(
          isSyncing: false,
          requiresSyncAuthentication: false,
          clearError: true,
        ),
      );
    } catch (error) {
      authenticationError = _messageFor(error);
      emit(
        state.copyWith(
          isSyncing: false,
          requiresSyncAuthentication: true,
          errorMessage: authenticationError,
        ),
      );
    } finally {
      _operationInProgress = false;
    }

    if (authenticationError != null) return authenticationError;
    await synchronizePending(refreshContext: true);
    return state.pendingCount == 0 && !state.requiresSyncAuthentication
        ? null
        : state.errorMessage ??
              'Some attendance records still need synchronization.';
  }

  void dismissSyncAuthenticationPrompt() {
    if (state.requiresSyncAuthentication) {
      emit(state.copyWith(requiresSyncAuthentication: false, clearError: true));
    }
  }

  Future<void> retrySynchronization(String localRecordId) async {
    if (_operationInProgress || state.isSyncing) return;
    final recordIndex = state.records.indexWhere(
      (record) =>
          record.localRecordId == localRecordId &&
          record.syncStatus == 'rejected',
    );
    if (recordIndex < 0) return;

    final record = state.records[recordIndex].copyWith(
      syncStatus: 'pending',
      clearSyncMessage: true,
    );
    _operationInProgress = true;
    try {
      await _repository.saveRecord(record);
      final records = [...state.records]..[recordIndex] = record;
      emit(state.copyWith(records: records, clearError: true));
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage:
              'Unable to queue this attendance record: ${_messageFor(error)}',
        ),
      );
      return;
    } finally {
      _operationInProgress = false;
    }

    if (state.isOnline) await synchronizePending(refreshContext: true);
  }

  Future<void> _synchronizeRecord(ClockingRecord record) async {
    try {
      await _repository.synchronize(record);
      final syncedRecord = record.copyWith(
        syncStatus: 'synced',
        clearSyncMessage: true,
      );
      await _repository.saveRecord(syncedRecord);
      final records = state.records
          .map(
            (item) => item.localRecordId == record.localRecordId
                ? syncedRecord
                : item,
          )
          .toList();
      emit(
        state.copyWith(
          records: records,
          lastActionMessage: 'Attendance synchronized.',
          clearError: true,
        ),
      );
    } on SocketException {
      throw const _NetworkUnavailable();
    } on HttpException {
      throw const _NetworkUnavailable();
    } on HandshakeException {
      throw const _NetworkUnavailable();
    } on TimeoutException {
      throw const _NetworkUnavailable();
    } on MobileApiException catch (error) {
      if (_isNetworkStatus(error.statusCode)) {
        throw const _NetworkUnavailable();
      }
      rethrow;
    }
  }

  Future<void> _markRejected(ClockingRecord record, String reason) async {
    final rejectedRecord = record.copyWith(
      syncStatus: 'rejected',
      syncMessage: reason,
    );
    await _repository.saveRecord(rejectedRecord);
    final records = state.records
        .map(
          (item) => item.localRecordId == record.localRecordId
              ? rejectedRecord
              : item,
        )
        .toList();
    emit(state.copyWith(records: records));
  }

  Future<void> _refreshContext() async {
    final context = await _repository.refreshContext(
      userId: _user.id,
      identity: _identity,
    );
    emit(state.copyWith(context: context));
  }

  Future<void> _refreshHistory() async {
    try {
      final history = await _repository.refreshAttendanceHistory(_user.id);
      emit(state.copyWith(history: history));
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage:
              'Attendance is synchronized, but recent history could not be refreshed: ${_messageFor(error)}',
        ),
      );
    }
  }

  Future<void> _refreshDashboardData() async {
    try {
      final profile = await _repository.refreshUserProfile();
      emit(
        state.copyWith(
          isAccountActive: profile.isAccountActive,
          isOnLeave: profile.isOnLeave,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage:
              'Unable to refresh account status: ${_messageFor(error)}',
        ),
      );
    }

    try {
      final holiday = await _repository.refreshHolidayStatus(_user.id);
      emit(state.copyWith(holidayStatus: holiday, isHolidayStatusLoaded: true));
    } catch (error) {
      emit(
        state.copyWith(
          isHolidayStatusLoaded: false,
          errorMessage:
              'Unable to verify today’s holiday status: ${_messageFor(error)}',
        ),
      );
    }

    try {
      final history = await _repository.refreshAttendanceHistory(_user.id);
      emit(state.copyWith(history: history));
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage:
              'Unable to refresh recent attendance: ${_messageFor(error)}',
        ),
      );
    }
  }

  bool _isNetworkStatus(int? statusCode) =>
      statusCode == null ||
      statusCode >= 500 ||
      statusCode == 408 ||
      statusCode == 429;

  bool _isAuthenticationRequired(Object error) =>
      error is MobileApiException && error.statusCode == 401;

  String _messageFor(Object error) {
    if (error is MobileApiException) return error.message;
    if (error is StateError || error is ArgumentError) return error.toString();
    return 'Please try again. ($error)';
  }
}

class _NetworkUnavailable implements Exception {
  const _NetworkUnavailable();
}
