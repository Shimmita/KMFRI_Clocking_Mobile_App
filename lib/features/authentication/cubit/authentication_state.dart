import '../model/authentication_result.dart';

class AuthenticationState {
  const AuthenticationState({
    this.isAuthenticating = false,
    this.result,
  });

  final bool isAuthenticating;
  final AuthenticationResult? result;
}
