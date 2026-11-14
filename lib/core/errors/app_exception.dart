/// Base class for errors the UI can show to the traveller.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class PaymentException extends AppException {
  const PaymentException(super.message);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// A capability that needs a real service which this build does not have.
class NotConfiguredException extends AppException {
  const NotConfiguredException(super.message);
}

/// Turns any thrown object into a message that is safe to display.
String describeError(Object error) =>
    error is AppException ? error.message : 'Something went wrong. Please try again.';
