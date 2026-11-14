import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/providers.dart';
import '../../shared/widgets/widgets.dart';
import 'auth_controller.dart';
import 'widgets/login_illustration.dart';

/// Sign-in: the travel illustration above a white panel with the form.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _remember = true;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _email.text = ref.read(authControllerProvider.notifier).rememberedEmail ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = Validators.email(_email.text);
    final passwordError = Validators.password(_password.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null || passwordError != null) return;
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text, password: _password.text, remember: _remember);
    if (ok && mounted) context.go(Routes.home);
  }

  Future<void> _social(SocialProvider provider) async {
    try {
      await ref.read(authControllerProvider.notifier).signInWith(provider);
      if (mounted) context.go(Routes.home);
    } catch (error) {
      if (mounted) showSysflyToast(context, describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final media = MediaQuery.of(context);
    // The panel starts 312 pt down a 956 pt tall screen in the reference.
    final panelTop = (media.size.height * 0.326).clamp(220.0, 340.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: SysflyColors.surface,
        body: SysflyLoadingOverlay(
          visible: auth.loading,
          title: 'Logging you in',
          subtitle: 'Getting your tickets ready',
          child: Stack(
            children: [
              Positioned(top: 0, left: 0, right: 0, height: panelTop + 32, child: const LoginIllustration()),
              Positioned.fill(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: panelTop),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(minHeight: media.size.height - panelTop),
                        decoration: const BoxDecoration(
                          color: SysflyColors.surface,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(SysflyRadius.card)),
                        ),
                        padding: EdgeInsets.fromLTRB(24, 10, 24, 24 + media.padding.bottom),
                        child: _form(auth),
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

  Widget _form(AuthState auth) {
    return AutofillGroup(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: const BoxDecoration(color: Color(0xFFE2E5EE), borderRadius: SysflyRadius.pillAll),
          ),
          const SizedBox(height: 18),
          Semantics(header: true, child: TrText('Welcome back', style: SysflyTypography.title.copyWith(fontSize: 26))),
          const SizedBox(height: 8),
          TrText('Your trips and boarding passes are waiting', style: SysflyTypography.bodySecondary),
          const SizedBox(height: 20),
          SysflyTextField(
            key: const ValueKey('login-email'),
            controller: _email,
            hint: 'Enter your email',
            icon: SysflyIcons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
              ref.read(authControllerProvider.notifier).clearError();
            },
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          SysflyTextField(
            key: const ValueKey('login-password'),
            controller: _password,
            focusNode: _passwordFocus,
            hint: 'Enter your password',
            icon: SysflyIcons.lock,
            obscure: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            errorText: _passwordError,
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
              ref.read(authControllerProvider.notifier).clearError();
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Semantics(
                checked: _remember,
                label: 'Remember me',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _remember = !_remember),
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SysflyCheckbox(value: _remember, size: 20),
                          const SizedBox(width: 10),
                          TrText('Remember me', style: SysflyTypography.bodySecondary.copyWith(fontSize: 13.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _TextLink(label: 'Forgot password?', onTap: () => _showForgotPassword(context)),
            ],
          ),
          AnimatedSize(
            duration: SysflyMotion.normal,
            alignment: Alignment.topCenter,
            child: auth.error == null
                ? const SizedBox(width: double.infinity, height: 6)
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: _ErrorBanner(message: auth.error!),
                  ),
          ),
          SysflyGradientButton(key: const ValueKey('login-submit'), label: 'Login', onPressed: auth.loading ? null : _submit),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: SysflyColors.divider, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TrText('Or continue with', style: SysflyTypography.caption),
              ),
              const Expanded(child: Divider(color: SysflyColors.divider, thickness: 1)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SysflyOutlineButton(
                  label: 'Google',
                  leading: const GoogleMark(),
                  height: 54,
                  expand: true,
                  radius: 18,
                  onPressed: () => _social(SocialProvider.google),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: SysflyOutlineButton(
                  label: 'Apple',
                  leading: const SysflyIcon(SysflyIcons.apple, size: 21, color: Colors.black),
                  height: 54,
                  expand: true,
                  radius: 18,
                  onPressed: () => _social(SocialProvider.apple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TrText("Don't have an account? ", style: SysflyTypography.bodySecondary.copyWith(fontSize: 13.5)),
              _TextLink(label: 'Create an account', onTap: () => context.push(Routes.signUp)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SysflyPressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ExcludeSemantics(child: TrText(label, style: SysflyTypography.link.copyWith(fontSize: 13.5))),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: SysflyColors.errorBg, borderRadius: BorderRadius.circular(SysflyRadius.md)),
        child: Row(
          children: [
            const SysflyIcon(SysflyIcons.warning, size: 18, color: SysflyColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: TrText(
                message,
                style: SysflyTypography.body.copyWith(fontSize: 13, color: SysflyColors.error, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showForgotPassword(BuildContext context) {
  return showSysflySheet<void>(context, builder: (_) => const _ForgotPasswordSheet());
}

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet();

  @override
  ConsumerState<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _email = TextEditingController();
  String? _error;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final error = Validators.email(_email.text);
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _sending = true);
    await ref.read(authControllerProvider.notifier).sendPasswordReset(_email.text);
    if (mounted) {
      setState(() {
        _sending = false;
        _sent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SysflySheetTitle(
            title: _sent ? 'Check your inbox' : 'Reset password',
            subtitle: _sent
                ? 'A reset link would be sent to ${_email.text.trim()}. This demo build sends no email.'
                : 'Enter the email you signed up with',
          ),
          const SizedBox(height: 18),
          if (!_sent) ...[
            SysflyTextField(
              controller: _email,
              hint: 'Enter your email',
              icon: SysflyIcons.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              errorText: _error,
              autofocus: true,
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 16),
            SysflyGradientButton(label: 'Send reset link', loading: _sending, onPressed: _send),
          ] else
            SysflyGradientButton(label: 'Back to login', onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
