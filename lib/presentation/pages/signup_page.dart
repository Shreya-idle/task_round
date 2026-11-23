import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validation/auth_validators.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_form_fields.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                      Text(
                        'Get started',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create an account to manage your tasks.',
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
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      AuthPasswordField(
                        controller: _confirmationController,
                        validator: (value) => AuthValidators.confirmation(
                          value,
                          _passwordController.text,
                        ),
                        enabled: !submitState.isLoading,
                        obscureText: _obscureConfirmation,
                        onToggleVisibility: () => setState(
                          () => _obscureConfirmation = !_obscureConfirmation,
                        ),
                        label: 'Confirm password',
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
                            : const Text('Create account'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: submitState.isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Already have an account? Sign in'),
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
