import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/widgets.dart';
import 'auth_controller.dart';

/// Account creation, in the same language as the sign-in panel.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nameError = Validators.fullName(_name.text);
    final emailError = Validators.email(_email.text);
    final passwordError = Validators.password(_password.text);
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (nameError != null || emailError != null || passwordError != null) return;
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signUp(name: _name.text, email: _email.text, password: _password.text);
    if (ok && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final clear = ref.read(authControllerProvider.notifier).clearError;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SysflyColors.surface,
        body: SysflyLoadingOverlay(
          visible: auth.loading,
          title: 'Creating your account',
          subtitle: 'Getting your tickets ready',
          child: Column(
            children: [
              SysflyHeader(title: 'Create account', onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + MediaQuery.paddingOf(context).bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TrText('Join sysfly', style: SysflyTypography.title.copyWith(fontSize: 26)),
                      const SizedBox(height: 8),
                      TrText('Book faster and keep every boarding pass in one place', style: SysflyTypography.bodySecondary),
                      const SizedBox(height: 24),
                      SysflyTextField(
                        controller: _name,
                        hint: 'Full name, as on your passport',
                        icon: SysflyIcons.user,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        errorText: _nameError,
                        onChanged: (_) => setState(() => _nameError = null),
                      ),
                      const SizedBox(height: 12),
                      SysflyTextField(
                        controller: _email,
                        hint: 'Enter your email',
                        icon: SysflyIcons.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        errorText: _emailError,
                        onChanged: (_) {
                          setState(() => _emailError = null);
                          clear();
                        },
                      ),
                      const SizedBox(height: 12),
                      SysflyTextField(
                        controller: _password,
                        hint: 'Create a password',
                        icon: SysflyIcons.lock,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        errorText: _passwordError,
                        onChanged: (_) => setState(() => _passwordError = null),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: TrText(
                            auth.error!,
                            style: SysflyTypography.body.copyWith(fontSize: 13, color: SysflyColors.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SysflyGradientButton(label: 'Create account', onPressed: auth.loading ? null : _submit),
                      const SizedBox(height: 14),
                      TrText(
                        'Accounts in this demo build live in memory and are cleared when the app closes.',
                        textAlign: TextAlign.center,
                        style: SysflyTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
