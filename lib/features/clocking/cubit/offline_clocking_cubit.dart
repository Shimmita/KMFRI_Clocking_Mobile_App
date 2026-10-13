import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/offline_clocking_repository.dart';
import 'offline_clocking_state.dart';

class OfflineClockingCubit extends Cubit<OfflineClockingState> {
  OfflineClockingCubit(this._repository)
      : super(
          OfflineClockingState(
            isClockedIn: _repository.isClockedIn,
            records: _repository.records,
          ),
        );

  final OfflineClockingRepository _repository;

  void clockIn() {
    _repository.clockIn();
    _emitClockingState('Clock in recorded offline.');
  }

  void clockOut() {
    _repository.clockOut();
    _emitClockingState('Clock out recorded offline.');
  }

  void _emitClockingState(String message) {
    emit(
      OfflineClockingState(
        isClockedIn: _repository.isClockedIn,
        records: _repository.records,
        lastActionMessage: message,
      ),
    );
  }
}
