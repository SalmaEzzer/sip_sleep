import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_palette.dart';
import 'auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final loading = auth.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F8FF), Color(0xFFF3F6FF), Color(0xFFF6F3FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  children: [
                    const _BrandHeader(
                      title: 'Inscription',
                      subtitle: 'Commencez à suivre votre bien-être',
                    ),
                    const SizedBox(height: 24),
                    _InputCard(
                      icon: LucideIcons.user,
                      child: TextField(
                        controller: nameCtrl,
                        decoration: _input('Nom d\'affichage'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InputCard(
                      icon: LucideIcons.mail,
                      child: TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _input('Email'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InputCard(
                      icon: LucideIcons.lock,
                      trailing: IconButton(
                        onPressed: () => setState(() => showPassword = !showPassword),
                        icon: Icon(showPassword ? LucideIcons.eyeOff : LucideIcons.eye, color: AppPalette.textMuted),
                      ),
                      child: TextField(
                        controller: passCtrl,
                        obscureText: !showPassword,
                        decoration: _input('Mot de passe (min. 6 caractères)'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                final password = passCtrl.text;
                                if (name.isEmpty || email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nom, email et mot de passe requis')),
                                  );
                                  return;
                                }
                                if (!_isValidEmail(email)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Format d\'email invalide')),
                                  );
                                  return;
                                }
                                if (password.trim().length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Mot de passe trop court (min. 6 caractères)')),
                                  );
                                  return;
                                }
                                try {
                                  await ref.read(authProvider.notifier).signup(
                                        name,
                                        email,
                                        password,
                                      );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Bienvenue ! 🎉 Compte créé avec succès')),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Créer mon compte',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      child: const Text('Déjà un compte ? Se connecter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppPalette.textMuted),
        border: InputBorder.none,
      );

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}

class _BrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BrandHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _iconBox(AppPalette.water, LucideIcons.droplets),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppPalette.textPrimary),
            ),
            const SizedBox(width: 10),
            _iconBox(AppPalette.sleep, LucideIcons.moon),
          ],
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 15, color: AppPalette.textMuted)),
      ],
    );
  }

  Widget _iconBox(Color color, IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _InputCard extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _InputCard({required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppPalette.textMuted),
          const SizedBox(width: 10),
          Expanded(child: child),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
