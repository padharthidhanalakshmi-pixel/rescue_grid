import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/incident_service.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login([String? email, String? password]) {
    final e = email ?? _email.text;
    final p = password ?? _password.text;
    final err = context.read<RescueStore>().login(e, p);
    setState(() => _error = err);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.3,
            colors: [Color(0xFF3A0E16), RgColors.navy],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
                const Center(child: PulseDot(color: RgColors.red, size: 16)),
                const SizedBox(height: 12),
                const Text('🚨 RescueGrid',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(height: 10),
                const Text(Brand.collegeName,
                    textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Text(Brand.region, textAlign: TextAlign.center, style: TextStyle(color: RgColors.muted)),
                const SizedBox(height: 6),
                const Text('Campus Emergency Response System',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RgColors.red, letterSpacing: 1.6, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: RgColors.red)),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: RgColors.red, minimumSize: const Size.fromHeight(54)),
                  onPressed: () => _login(),
                  child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('DEMO ACCOUNTS'),
                  onPressed: _showDemoAccounts,
                ),
                const SizedBox(height: 20),
                const Center(child: Pill('DEMO MODE · test accounts only', color: RgColors.amber, dense: true)),
                const BrandFooter(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showDemoAccounts() {
    final groups = <String, List<DemoAccount>>{
      'ADMIN': [DemoCredentials.admin],
      'RESPONDERS': DemoCredentials.responders,
      'STUDENTS': DemoCredentials.students,
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: RgColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (ctx, scroll) => ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
          const Text('DEMO ACCOUNTS — tap to sign in',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          const Text('Test accounts for the hackathon demo. Not real users.',
              style: TextStyle(color: RgColors.muted, fontSize: 12)),
          for (final g in groups.entries) ...[
            SectionTitle(g.key),
            for (final a in g.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: () {
                    Navigator.pop(ctx);
                    _email.text = a.email;
                    _password.text = a.password;
                    _login(a.email, a.password);
                  },
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text('${a.email}  ·  ${a.password}',
                            style: AppTheme.mono.copyWith(color: RgColors.muted, fontSize: 12)),
                      ]),
                    ),
                    const Icon(Icons.login, color: RgColors.blue),
                  ]),
                ),
              ),
          ],
        ]),
      ),
    );
  }
}
