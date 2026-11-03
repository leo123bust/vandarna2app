import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

String _authError(Object e) {
  if (e is UnsupportedError) return e.message ?? 'Не се поддържа.';
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'Невалиден имейл адрес.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Грешен имейл или парола.';
      case 'email-already-in-use':
        return 'Този имейл вече е регистриран.';
      case 'weak-password':
        return 'Паролата е твърде слаба (поне 6 символа).';
      case 'network-request-failed':
        return 'Няма връзка с интернет.';
      case 'too-many-requests':
        return 'Твърде много опити. Опитай по-късно.';
    }
    return 'Грешка при вход: ${e.code}';
  }
  return 'Грешка: $e';
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {bool closeOnSuccess = true}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && closeOnSuccess && context.read<AppState>().user != null) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showSnack(context, _authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    _run(() => _register
        ? s.register(_username.text, _email.text, _password.text)
        : s.signIn(_email.text, _password.text));
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      showSnack(context, 'Въведи имейл адреса си, за да получиш линк за нова парола.');
      return;
    }
    await _run(() async {
      await context.read<AppState>().resetPassword(email);
      if (mounted) showSnack(context, 'Изпратихме линк за възстановяване на $email.');
    }, closeOnSuccess: false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(backgroundColor: c.bg, elevation: 0, scrolledUnderElevation: 0),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
          Text(_register ? 'Създай акаунт' : 'Вход', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          const SizedBox(height: 6),
          Text('Влез, за да добавяш сгради, да потвърждаваш информация и да пазиш любими.', style: TextStyle(color: c.textMuted, height: 1.4)),
          const SizedBox(height: 22),
          if (!s.firebaseReady)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(18)),
              child: Text('Демо режим: Firebase не е конфигуриран в тази версия, затова регистрация и вход са изключени. '
                  'Следвай README, за да включиш акаунтите.',
                  style: TextStyle(color: c.textMuted, height: 1.4)),
            ),
          Form(
            key: _form,
            child: Column(children: [
              if (_register) ...[
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Потребителско име'),
                  validator: (v) => (v ?? '').trim().length < 3 ? 'Поне 3 символа' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Имейл'),
                validator: (v) => (v ?? '').contains('@') ? null : 'Невалиден имейл',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Парола',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v ?? '').length < 6 ? 'Поне 6 символа' : null,
              ),
            ]),
          ),
          if (!_register)
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _busy ? null : _forgot, child: const Text('Забравена парола?'))),
          const SizedBox(height: 8),
          PrimaryButton(
            label: _register ? 'Регистрация' : 'Вход',
            busy: _busy,
            onPressed: s.firebaseReady ? _submit : null,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: const StadiumBorder()),
            onPressed: (_busy || !s.firebaseReady) ? null : () => _run(s.signInWithGoogle),
            icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
            label: const Text('Продължи с Google'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _register = !_register),
            child: Text(_register ? 'Вече имаш акаунт? Вход' : 'Нямаш акаунт? Регистрирай се'),
          ),
        ]),
      ),
    );
  }
}
