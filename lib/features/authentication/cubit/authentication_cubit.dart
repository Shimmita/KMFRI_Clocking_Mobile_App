import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/authentication_repository.dart';
import 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit(this._repository) : super(const AuthenticationState());

  final AuthenticationRepository _repository;

  Future<void> authenticate() async {
    if (state.isAuthenticating) return;

    emit(const AuthenticationState(isAuthenticating: true));
    final result = await _repository.authenticate();
    if (!isClosed) {
      emit(AuthenticationState(result: result));
    }
  }
}
