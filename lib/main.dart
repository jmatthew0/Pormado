import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'screens/add_item_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/outfits_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'state.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => Auth()..load()),
      ],
      child: const PormadoApp(),
    ),
  );
}

class PormadoApp extends StatelessWidget {
  const PormadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pormado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: C.green, surface: C.bg),
        textTheme: GoogleFonts.interTextTheme(),
        splashFactory: InkRipple.splashFactory,
      ),
      home: const Gate(),
    );
  }
}

/// Shows login until signed in, then the app. Also refreshes weather when
/// you come back to the app (so it follows you when you relocate).
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> with WidgetsBindingObserver {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _started)
      context.read<AppState>().onResume();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<Auth>();
    final st = context.watch<AppState>();
    if (!a.loaded) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: C.green)));
    }
    if (!a.signedIn) return const AuthScreen();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.read<AppState>().init());
    }
    if (!st.ready) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: C.green)));
    }
    if (!st.onboarded) return const OnboardingScreen();
    return const Shell();
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return ValueListenableBuilder<int>(
      valueListenable: s.tab,
      builder: (context, i, _) {
        Widget nav(int idx, IconData icon, String label) {
          final on = i == idx;
          return Expanded(
            child: InkWell(
              onTap: () => s.tab.value = idx,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 24,
                        color: on ? C.green : const Color(0xFFA8A49B)),
                    const SizedBox(height: 3),
                    Text(label, style: sans(11, color: on ? C.green : C.muted)),
                  ]),
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(index: i, children: const [
            HomeScreen(),
            WardrobeScreen(),
            OutfitsScreen(),
            CalendarScreen(),
          ]),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            backgroundColor: C.green,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddItemScreen())),
            child: const Icon(Icons.add, size: 30),
          ),
          bottomNavigationBar: BottomAppBar(
            color: Colors.white,
            height: 72,
            padding: EdgeInsets.zero,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: Row(children: [
              nav(0, Icons.home_rounded, 'Today'),
              nav(1, Icons.checkroom_rounded, 'Wardrobe'),
              const SizedBox(width: 72),
              nav(2, Icons.layers_rounded, 'Outfits'),
              nav(3, Icons.calendar_month_rounded, 'Calendar'),
            ]),
          ),
        );
      },
    );
  }
}
