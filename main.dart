import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DuniyaConnectApp());
}

const navy = Color(0xFF09264B);
const blue = Color(0xFF1677F2);
const green = Color(0xFF20C878);
const pale = Color(0xFFF3F7FC);

class DuniyaConnectApp extends StatelessWidget {
  const DuniyaConnectApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DUNIYA CONNECT',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: blue),
      scaffoldBackgroundColor: pale,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.blueGrey.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: blue, width: 1.5)),
      ),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasData) return const MainShell();
      return const AuthPage();
    },
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = true;
  bool _hidePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = FirebaseAuth.instance;
      final email = _email.text.trim();
      if (_isRegister) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: email, password: _password.text,
        );
        final displayName = _name.text.trim();
        if (displayName.isNotEmpty) {
          await credential.user?.updateDisplayName(displayName);
          await credential.user?.sendEmailVerification();
          await credential.user?.reload();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An ƙirƙiri account. Duba imel ɗinka don tabbatarwa.')),
          );
        }
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: _password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'email-already-in-use' => 'An riga an yi rajista da wannan imel.',
        'invalid-email' => 'Imel ɗin bai dace ba.',
        'weak-password' => 'Ka zaɓi kalmar sirri mai ƙarfi.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Imel ko kalmar sirri ba daidai ba ce.',
        'network-request-failed' => 'Matsalar intanet. Ka sake gwadawa.',
        'too-many-requests' => 'An yi ƙoƙari da yawa. Ka ɗan jira.',
        'operation-not-allowed' => 'Ba a kunna Email/Password a Firebase ba tukuna.',
        _ => e.message ?? 'An samu kuskure. Ka sake gwadawa.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ba a iya kammala aikin ba. Ka duba saitin Firebase da intanet.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: navy,
                          child: Icon(Icons.public, color: green, size: 42),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Center(child: Text('DUNIYA CONNECT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navy))),
                      const SizedBox(height: 6),
                      Center(child: Text(_isRegister ? 'Ƙirƙiri sabon account ɗinka' : 'Barka da dawowa!', style: const TextStyle(color: Colors.black54))),
                      const SizedBox(height: 26),
                      if (_isRegister) ...[
                        const Text('Suna', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'Shigar da cikakken suna', prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => _isRegister && (v == null || v.trim().isEmpty) ? 'Da fatan shigar da sunanka.' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('Imel', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: 'misali@email.com', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Da fatan shigar da imel.';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Imel ɗin bai yi daidai ba.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Kalmar sirri', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'Aƙalla haruffa 6',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Da fatan shigar da kalmar sirri.';
                          if (v.length < 6) return 'Kalmar sirri ta kasance aƙalla haruffa 6.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isRegister ? 'Ƙirƙiri Account' : 'Shiga', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_isRegister ? 'Kana da account?' : 'Ba ka da account?'),
                        TextButton(
                          onPressed: () => setState(() {
                            _isRegister = !_isRegister;
                            _formKey.currentState?.reset();
                          }),
                          child: Text(_isRegister ? 'Shiga' : 'Yi rajista', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      const Text('Ana amfani da Firebase Authentication don kare rajista da shiga.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final labels = const ['Home', 'Videos', 'Messages', 'Groups', 'Profile'];
  final icons = const [Icons.home_rounded, Icons.play_circle_fill_rounded, Icons.chat_bubble_rounded, Icons.groups_rounded, Icons.person_rounded];
  final pages = const [FeedPage(), VideosPage(), MessagesPage(), GroupsPage(), ProfilePage()];
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: const Row(children: [
        Icon(Icons.public, color: green, size: 30), SizedBox(width: 9),
        Text('DUNIYA ', style: TextStyle(fontWeight: FontWeight.w900)),
        Text('CONNECT', style: TextStyle(color: green, fontWeight: FontWeight.w900)),
      ]), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search)), IconButton(tooltip: 'Fita', onPressed: () async { await FirebaseAuth.instance.signOut(); }, icon: const Icon(Icons.logout)), const SizedBox(width: 8)]),
      body: Row(children: [
        if (wide) NavigationRail(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), labelType: NavigationRailLabelType.all,
          destinations: List.generate(labels.length, (i) => NavigationRailDestination(icon: Icon(icons[i]), label: Text(labels[i])))),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850), child: pages[index]))),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v),
        destinations: List.generate(labels.length, (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i]))),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create post: backend coming soon'))), icon: const Icon(Icons.add), label: const Text('Create')),
    );
  }
}

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [navy, blue])),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HAƊIN KAI A DUNIYA 🌍', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
        SizedBox(height: 8), Text('Duk abin da kake so, a wuri guda!', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        SizedBox(height: 8), Text('Sada zumunta • Saƙonni • Bidiyo • Groups', style: TextStyle(color: Colors.white70)),
      ])),
    const SizedBox(height: 14),
    const Card(child: ListTile(leading: CircleAvatar(child: Icon(Icons.person)), title: Text('What would you like to share today?'), trailing: Icon(Icons.photo_library_outlined))),
    const PostCard(name: 'Aisha Musa', handle: '@aisha_m', text: 'Sannu duniya! Barka da zuwa DUNIYA CONNECT. Mu haɗu, mu koya, mu bunƙasa tare. 🌍', icon: Icons.landscape),
    const PostCard(name: 'Usman Bello', handle: '@usman_b', text: 'Small steps every day lead to big results. Keep going! 💚', icon: Icons.lightbulb_outline),
  ]);
}

class PostCard extends StatelessWidget {
  final String name, handle, text; final IconData icon;
  const PostCard({super.key, required this.name, required this.handle, required this.text, required this.icon});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 14), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const CircleAvatar(backgroundColor: blue, child: Icon(Icons.person, color: Colors.white)), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), Text(handle, style: const TextStyle(color: Colors.black54, fontSize: 12))])), const Icon(Icons.more_horiz)]),
    const SizedBox(height: 12), Text(text, style: const TextStyle(height: 1.4)), const SizedBox(height: 12),
    Container(height: 110, width: double.infinity, decoration: BoxDecoration(color: blue.withOpacity(.08), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 48, color: blue)),
    Row(children: [TextButton.icon(onPressed: () {}, icon: const Icon(Icons.favorite_border), label: const Text('Like')), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.mode_comment_outlined), label: const Text('Comment')), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.share_outlined), label: const Text('Share'))]),
  ])));
}

class VideosPage extends StatelessWidget {
  const VideosPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Heading(icon: Icons.play_circle_fill, title: 'Short Videos', subtitle: 'Gajerun bidiyo daga al’ummar DUNIYA CONNECT'),
    for (final title in ['Sabon salo daga Kano ✨', 'Learn something new every day 📚', 'Arewa vibes 🌍'])
      Card(child: Container(height: 170, margin: const EdgeInsets.all(8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [navy, blue])),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.play_circle_fill, size: 54, color: Colors.white), const SizedBox(height: 8), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Text('Demo video · Upload feature coming soon', style: TextStyle(color: Colors.white70))])))),
  ]);
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Heading(icon: Icons.chat, title: 'Messages', subtitle: 'Saƙonni a wuri guda'),
    for (final row in const [('Aisha Musa', 'Sannu! Yaya kake?', '09:32'), ('Family Group', 'Malam ya aiko da saƙo', '08:45'), ('Usman Bello', 'Sai mun haɗu gobe.', 'Jiya'), ('Farida Sani', 'Na gode sosai 😊', 'Jiya')])
      Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(row.$1), subtitle: Text(row.$2), trailing: Text(row.$3), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Real-time chat will be added with Firebase.'))))),
  ]);
}

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Heading(icon: Icons.groups, title: 'Groups', subtitle: 'Haɗu da mutane masu ra’ayi iri ɗaya'),
    for (final row in const [('Hausa Culture', '6.3K members'), ('Technology & Innovation', '2.1K members'), ('Business & Marketing', '980 members'), ('Travel & Adventure', '720 members')])
      Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.groups)), title: Text(row.$1), subtitle: Text(row.$2), trailing: OutlinedButton(onPressed: () {}, child: const Text('Join')))),
  ]);
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(22)), child: const Column(children: [
      CircleAvatar(radius: 42, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: blue)), SizedBox(height: 12),
      Text('Your DUNIYA Profile', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      SizedBox(height: 4), Text('Create an account to set up your profile', style: TextStyle(color: Colors.white70)),
    ])),
    const SizedBox(height: 16), const Card(child: ListTile(leading: Icon(Icons.lock_outline), title: Text('Privacy & Security'), subtitle: Text('Account security settings coming soon'))),
    const Card(child: ListTile(leading: Icon(Icons.language), title: Text('Language'), subtitle: Text('Hausa · English · More languages planned'))),
  ]);
}

class Heading extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const Heading({super.key, required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
    CircleAvatar(backgroundColor: blue.withOpacity(.12), child: Icon(icon, color: blue)), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(color: Colors.black54))])),
  ]));
}
