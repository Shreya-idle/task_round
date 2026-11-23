import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validation/auth_validators.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_form_fields.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome back',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to manage your tasks.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AuthEmailField(
                        controller: _emailController,
                        validator: AuthValidators.email,
                        enabled: !submitState.isLoading,
                      ),
                      const SizedBox(height: 16),
                      AuthPasswordField(
                        controller: _passwordController,
                        validator: AuthValidators.password,
                        enabled: !submitState.isLoading,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (submitState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          submitState.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: submitState.isLoading ? null : _submit,
                        child: submitState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: submitState.isLoading
                            ? null
                            : () {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .clearError();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SignupPage(),
                                  ),
                                );
                              },
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
