abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String phoneNumber;
  LoginRequested({required this.phoneNumber});
}

class LogoutRequested extends AuthEvent {}
