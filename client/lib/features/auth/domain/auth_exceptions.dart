abstract class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class LogInFailure extends AuthException {
  LogInFailure([
    super.message =
        'An unknown exception occurred during log in. Please try again or contact support for help.',
  ]);

  factory LogInFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return LogInFailure('Email is invalid or incorrectly formatted. Please double-check your input.');
      
      case 'invalid-credential':
        return LogInFailure('Invalid credentials. Please check your email and password and try again.');

      case 'user-disabled':
        return LogInFailure('This user has been disabled. Please contact support for help.');

      case 'too-many-requests':
        return LogInFailure('Too many requests. Please try again later.');

      case 'network-request-failed':
        return LogInFailure('Network error. Please ensure you\'re connected to the internet.');

      case 'operation-not-allowed':
        return LogInFailure('Log in is not enabled at this time. Please try again later.');

      default:
        return LogInFailure();
    }
  }
}

class SignUpFailure extends AuthException {
  SignUpFailure([
    super.message =
        'An unknown exception occurred during sign up. Please try again or contact support for help.',
  ]);

  factory SignUpFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return SignUpFailure('Email is invalid or incorrectly formatted. Please double-check your input.');

      case 'email-already-in-use':
        return SignUpFailure('An account already exists for that email.');

      case 'operation-not-allowed':
        return SignUpFailure('Sign up is not enabled at this time. Please try again later.');

      case 'weak-password':
        return SignUpFailure('Please enter a stronger password.');

      case 'network-request-failed':
        return SignUpFailure('Network error. Please ensure you\'re connected to the internet.');

      case 'too-many-requests':
        return SignUpFailure('Too many requests. Please try again later.');

      default:
        return SignUpFailure();
    }
  }
}

class SignOutFailure extends AuthException {
  SignOutFailure([
    super.message = 'An unknown exception occurred during sign out.',
  ]);
}
