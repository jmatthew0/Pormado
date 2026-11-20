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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                      color: C.green, shape: BoxShape.circle),
                  child: const Icon(Icons.checkroom_rounded,
                      color: Colors.white, size: 38),
                ),
              ),
              const SizedBox(height: 18),
              Center(child: Text('Pormado', style: serif(44))),
              const SizedBox(height: 8),
              Center(
                  child: Text('Your closet, in your pocket.',
                      style: sans(15, color: C.muted))),
              const SizedBox(height: 28),
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
              const SizedBox(height: 18),
              Panel(
                radius: 28,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(signup ? 'Create your wardrobe' : 'Welcome back',
                          style: serif(24)),
                      const SizedBox(height: 18),
                      if (signup) AppField(label: 'Name', controller: nameC),
                      AppField(
                          label: 'Email',
                          controller: emailC,
                          type: TextInputType.emailAddress),
                      AppField(
                        label: 'Password',
                        controller: passC,
                        obscure: hide,
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
                              style: sans(13.5,
                                  color: C.terracotta, w: FontWeight.w600)),
                        ),
                    ]),
              ),
              const SizedBox(height: 18),
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
