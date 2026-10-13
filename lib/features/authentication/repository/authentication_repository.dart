import '../model/authentication_result.dart';
import '../service/authentication_service.dart';

class AuthenticationRepository {
  AuthenticationRepository(this._service);

  final AuthenticationService _service;

  Future<AuthenticationResult> authenticate() => _service.authenticate();
}
