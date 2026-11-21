import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth.dart';
import '../ui.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool signup = false;
  bool busy = false;
  bool hide = true;
  String? error;
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    final a = context.read<Auth>();
    final err = signup
        ? await a.signUp(nameC.text, emailC.text, passC.text)
        : await a.signIn(emailC.text, passC.text);
    if (!mounted) return;
    setState(() {
      busy = false;
      error = err;
    });
  }

  Widget _piece(IconData icon, Color bg, Color fg, double h) => Container(
        width: 74,
        height: h,
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ]),
        child: Icon(icon, color: fg, size: 34),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: C.green, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.checkroom_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Text('Pormado', style: serif(24)),
              ]),
              const SizedBox(height: 18),
              Container(
                height: 190,
                decoration: BoxDecoration(
                    color: C.sand, borderRadius: BorderRadius.circular(28)),
                child: Stack(children: [
                  Center(
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _piece(Icons.checkroom_outlined, Colors.white,
                              C.green, 92),
                          const SizedBox(width: 16),
                          _piece(Icons.layers_outlined, const Color(0xFF1F2A44),
                              Colors.white, 116),
                          const SizedBox(width: 16),
                          _piece(Icons.woman, const Color(0xFFB7C5A8),
                              Colors.white, 130),
                        ]),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.wb_cloudy_rounded,
                            size: 16, color: Color(0xFFE0AE4F)),
                        const SizedBox(width: 6),
                        Text('Weather-ready outfits',
                            style: sans(12.5, w: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              Text('Dress for today,\nwithout opening\nyour closet.',
                  style: serif(32)),
              const SizedBox(height: 10),
              Text(
                  'Digitize your wardrobe, build outfits and get suggestions based on the weather.',
                  style: sans(14.5, color: C.muted, height: 1.4)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: C.line)),
                child: Row(children: [
                  for (final e in ['Sign in', 'Create account'].asMap().entries)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          signup = e.key == 1;
                          error = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              color: (signup ? 1 : 0) == e.key
                                  ? C.ink
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26)),
                          alignment: Alignment.center,
                          child: Text(e.value,
                              style: sans(15,
                                  color: (signup ? 1 : 0) == e.key
                                      ? Colors.white
                                      : C.muted,
                                  w: FontWeight.w600)),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 20),
              if (signup)
                AppField(
                    label: 'Name',
                    controller: nameC,
                    hint: 'Your name',
                    icon: Icons.person_outline),
              AppField(
                  label: 'Email',
                  controller: emailC,
                  type: TextInputType.emailAddress,
                  hint: 'you@email.com',
                  icon: Icons.mail_outline),
              AppField(
                label: 'Password',
                controller: passC,
                obscure: hide,
                hint: '••••••••',
                icon: Icons.lock_outline,
                onSubmitted: busy ? null : _submit,
                suffix: IconButton(
                  icon: Icon(
                      hide
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: C.muted),
                  onPressed: () => setState(() => hide = !hide),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(error!,
                      style:
                          sans(13.5, color: C.terracotta, w: FontWeight.w600)),
                ),
              Btn(
                  busy
                      ? 'Please wait…'
                      : (signup ? 'Create account' : 'Sign in'),
                  icon: Icons.arrow_forward,
                  onTap: busy ? null : _submit),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.read<Auth>().continueAsGuest(),
                  child: Text('Continue as guest',
                      style: sans(15, color: C.green, w: FontWeight.w700)),
                ),
              ),
            ]),
      ),
    );
  }
}
