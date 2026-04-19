import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _showEmailForm = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    // 로그인 성공 시 이전 화면으로 돌아감
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 245, 245, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 245, 245, 1),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // 앱 로고 — 남은 공간에 맞게 축소
              Expanded(
                child: Center(
                  child: Image.asset('assets/img/logo2.png'),
                ),
              ),

              // ── 소셜 로그인 버튼 ──
              _SocialButton(
                icon: Icons.g_mobiledata,
                label: l10n.continueWithGoogle,
                onPressed:
                    isLoading ? null : _signInWithGoogle,
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                _SocialButton(
                  icon: Icons.apple,
                  label: l10n.continueWithApple,
                  onPressed: isLoading ? null : _signInWithApple,
                ),
              ],

              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(l10n.orDivider,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 20),

              // ── 이메일 로그인 ──
              if (!_showEmailForm)
                _SocialButton(
                  icon: Icons.email_outlined,
                  label: l10n.loginWithEmail,
                  onPressed: () => setState(() => _showEmailForm = true),
                )
              else
                _EmailForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isLoading: isLoading,
                  onSubmit: _signInWithEmail,
                ),

              const SizedBox(height: 12),
              // 회원가입 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.noAccountYet),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: Text(l10n.signUp),
                  ),
                ],
              ),

              // 로그인 없이 사용
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: Text(l10n.useWithoutLogin),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _signInWithGoogle() =>
      ref.read(authProvider.notifier).signInWithGoogle();

  void _signInWithApple() =>
      ref.read(authProvider.notifier).signInWithApple();

  void _signInWithEmail() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }
}

// ── 소셜 로그인 버튼 위젯 ───────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

// ── 이메일 폼 위젯 ─────────────────────────────────────────────────────────

class _EmailForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _EmailForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.email,
              border: const OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? l10n.invalidEmail : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.password,
              border: const OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.length < 8) ? l10n.passwordMinLength : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.loginTitle),
            ),
          ),
        ],
      ),
    );
  }
}
