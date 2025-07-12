import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_text_form_field.dart';
import '../domain/auth_exceptions.dart';
import '../application/auth_controller.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthMode _authMode = AuthMode.signIn; // Default to sign-in

  // Text editing controllers
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late final TapGestureRecognizer _switchAuthModeRecognizer;

  // Focus nodes
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _switchAuthModeRecognizer = TapGestureRecognizer()
      ..onTap = _switchAuthMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _switchAuthModeRecognizer.dispose();
    super.dispose();
  }

  // --- Validation Methods ---
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email.';
    }
    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_authMode == AuthMode.signUp) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password.';
      }
      if (value != _passwordController.text) {
        return 'Passwords do not match.';
      }
    }
    return null;
  }

  // --- Action Methods ---
  void _switchAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
      _formKey.currentState?.reset();
      // Clear controllers explicitly if reset doesn't cover all cases or for more control
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      // Optionally, request focus on the first field
      // Future.microtask(() => FocusScope.of(context).requestFocus(_emailFocusNode));
    });
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Note: onSaved is not strictly needed here as we are using controllers directly.
    // _formKey.currentState!.save();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final authNotifier = ref.read(authControllerProvider.notifier);

    if (_authMode == AuthMode.signIn) {
      await authNotifier.signInWithEmailAndPassword(email, password);
    } else {
      await authNotifier.signUpWithEmailAndPassword(email, password);
    }
  }

  // --- UI Building Helper Methods ---
  Widget _buildEmailField() {
    return AuthTextFormField(
      controller: _emailController,
      labelText: 'Email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
      focusNode: _emailFocusNode,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
    );
  }

  Widget _buildPasswordField() {
    return AuthTextFormField(
      controller: _passwordController,
      labelText: 'Password',
      prefixIcon: Icons.lock_outline,
      obscureText: true,
      validator: _validatePassword,
      focusNode: _passwordFocusNode,
      onFieldSubmitted:
          _authMode == AuthMode.signIn
              ? (_) => _submitForm()
              : (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocusNode),
    );
  }

  Widget _buildConfirmPasswordField() {
    if (_authMode == AuthMode.signUp) {
      return Column(
        children: [
          const SizedBox(height: 16),
          AuthTextFormField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: _validateConfirmPassword,
            focusNode: _confirmPasswordFocusNode,
            onFieldSubmitted: (_) => _submitForm(),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSubmitButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        onPressed: isLoading ? null : _submitForm,
        child:
            isLoading
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                )
                : Text(_authMode == AuthMode.signIn ? 'Sign In' : 'Sign Up'),
      ),
    );
  }

  Widget _buildAuthModeSwitchLink() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: <TextSpan>[
          TextSpan(text: _authMode == AuthMode.signIn ? "Don't have an account? " : 'Already have an account? '),
          TextSpan(
            text: _authMode == AuthMode.signIn ? 'Sign Up' : 'Sign In',
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            recognizer: _switchAuthModeRecognizer,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          String displayMessage;
          if (error is AuthException) {
            // Check if it's our custom AuthException
            displayMessage = error.message; // Use the specific message from AuthException
          } else {
            // Log the full error for developers if a logger is available
            // ref.read(loggerProvider).error("AuthScreen UI Error", error, stackTrace);
            debugPrint("AuthScreen UI Error: $error \n$stackTrace"); // For debugging
            displayMessage = "An unexpected error occurred. Please try again.";
          }

          // Ensure widget is still mounted before showing SnackBar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(displayMessage), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
      );
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  _authMode == AuthMode.signIn ? 'Welcome Back!' : 'Create Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _authMode == AuthMode.signIn ? 'Sign in to continue.' : 'Fill in the details to get started.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                _buildConfirmPasswordField(),
                const SizedBox(height: 24),
                _buildSubmitButton(isLoading),
                const SizedBox(height: 24),
                _buildAuthModeSwitchLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
