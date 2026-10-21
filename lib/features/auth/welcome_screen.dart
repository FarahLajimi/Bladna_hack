import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth/auth_service.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/contours.dart';
import '../../state/session_controller.dart';

enum _Mode { signIn, create }

/// Entry point: sign in, create an account, or continue as a local guest.
/// With no provider configured the forms validate input, then explain that
/// accounts need setup — nothing pretends to sign in.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    final session = context.read<SessionController>();
    setState(() => _busy = true);
    try {
      if (_mode == _Mode.signIn) {
        await session.signIn(_email.text, _password.text);
      } else {
        await session.createAccount(_name.text, _email.text, _password.text);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final emailError = AuthValidators.email(_email.text);
    if (emailError != null) {
      setState(() => _error = 'Enter your email above first, then tap "Forgot password?".');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<SessionController>().sendPasswordReset(_email.text);
      if (mounted) setState(() => _error = 'If an account exists for that address, a reset link has been sent.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _guest() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.limestone,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _GuestSheet(),
    );
    if (name == null || !mounted) return;
    await context.read<SessionController>().continueAsGuest(name);
  }

  @override
  Widget build(BuildContext context) {
    final configured = context.select<SessionController, bool>((s) => s.auth.isConfigured);
    return Scaffold(
      backgroundColor: AppColors.limestone,
      body: Stack(
        children: [
          const Positioned(top: -40, right: -80, child: ContourMotif(size: 340, opacity: 0.09)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: BladnaLockup(markSize: 52)),
                    const SizedBox(height: 28),
                    Text('Greater Tunis, from space.', style: AppText.title.copyWith(fontSize: 30)),
                    const SizedBox(height: 8),
                    Text(
                      'Investigate a wetland, a lagoon and a landfill on real satellite imagery. '
                      'Trace, measure, compare and collect field evidence — one place at a time.',
                      style: AppText.bodyText.copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 26),
                    SegmentedButton<_Mode>(
                      segments: const [
                        ButtonSegment(value: _Mode.signIn, label: Text('Sign in')),
                        ButtonSegment(value: _Mode.create, label: Text('Create account')),
                      ],
                      selected: {_mode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setState(() {
                        _mode = s.first;
                        _error = null;
                      }),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.midnight,
                        selectedForegroundColor: AppColors.onDark,
                        side: const BorderSide(color: AppColors.mineral),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _form,
                      child: Column(
                        children: [
                          if (_mode == _Mode.create) ...[
                            _Field(controller: _name, label: 'Name', validator: AuthValidators.name, autofill: const [AutofillHints.name]),
                            const SizedBox(height: 12),
                          ],
                          _Field(
                            controller: _email,
                            label: 'Email',
                            keyboard: TextInputType.emailAddress,
                            validator: AuthValidators.email,
                            autofill: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _password,
                            label: 'Password',
                            obscure: _obscure,
                            validator: AuthValidators.password,
                            autofill: const [AutofillHints.password],
                            suffix: IconButton(
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_mode == _Mode.signIn)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: _busy ? null : _reset, child: const Text('Forgot password?')),
                      )
                    else
                      const SizedBox(height: 12),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(_error!, style: AppText.small.copyWith(color: AppColors.gentleError)),
                        ),
                      ),
                    BladnaButton(
                      label: _busy ? 'Please wait…' : (_mode == _Mode.signIn ? 'Sign in' : 'Create account'),
                      style: BladnaButtonStyle.secondary,
                      onPressed: _busy ? null : _submit,
                    ),
                    const SizedBox(height: 20),
                    const _OrDivider(),
                    const SizedBox(height: 20),
                    BladnaButton(
                      label: 'Continue as guest',
                      icon: Icons.explore_outlined,
                      onPressed: _busy ? null : _guest,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      configured
                          ? 'Guests play with a local profile on this phone. Sign in to link progress to an account.'
                          : 'Accounts need a sign-in provider that is not configured in this build yet. '
                              'As a guest, your progress is saved only on this phone — nothing is uploaded.',
                      style: AppText.small.copyWith(fontSize: 12.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboard,
    this.obscure = false,
    this.suffix,
    this.autofill,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;
  final Iterable<String>? autofill;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboard,
      obscureText: obscure,
      autocorrect: false,
      autofillHints: autofill,
      style: AppText.bodyText,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.mineral)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.mineral)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.midnight, width: 1.6)),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.mineral)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: AppText.label)),
        const Expanded(child: Divider(color: AppColors.mineral)),
      ],
    );
  }
}

class _GuestSheet extends StatefulWidget {
  const _GuestSheet();

  @override
  State<_GuestSheet> createState() => _GuestSheetState();
}

class _GuestSheetState extends State<_GuestSheet> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Play as a guest', style: AppText.heading),
          const SizedBox(height: 6),
          Text(
            'A local profile on this phone. No account, no email, nothing synced. You can sign out later without losing progress on this device.',
            style: AppText.small,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _c,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Name in your field book (optional)'),
          ),
          const SizedBox(height: 8),
          BladnaButton(label: 'Start exploring', icon: Icons.arrow_forward_rounded, onPressed: () => Navigator.of(context).pop(_c.text)),
        ],
      ),
    );
  }
}
