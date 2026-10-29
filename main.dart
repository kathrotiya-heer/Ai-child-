import 'auth_screen.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'auth_service.dart';
import 'learning_screen.dart';

// Multiple-child support uses the active child in DatabaseHelper.
// Original SafeLearn UI and feature flow are preserved.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SafeLearnApp());
}

// ============================================================
// APP
// ============================================================

class SafeLearnApp extends StatelessWidget {
  const SafeLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeLearn',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        fontFamily: 'Arial',
      ),
      home: const AppStartGate(),
    );
  }
}

// ============================================================
// AUTH START GATE
// ============================================================

class AppStartGate extends StatefulWidget {
  const AppStartGate({super.key});

  @override
  State<AppStartGate> createState() => _AppStartGateState();
}

class _AppStartGateState extends State<AppStartGate> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: DatabaseHelper.instance.getAuthSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data;
        if (session == null) return const AuthScreen();
        return const WelcomeScreen();
      },
    );
  }
}

// ============================================================
// COLORS
// ============================================================

class AppColors {
  static const Color cream = Color(0xFFFFFBF2);
  static const Color navy = Color(0xFF243B64);
  static const Color blue = Color(0xFF4B93E8);
  static const Color purple = Color(0xFF8060D5);
  static const Color green = Color(0xFF7BCB45);
  static const Color yellow = Color(0xFFFFC928);
  static const Color pink = Color(0xFFFF6F91);

  static const Color lightBlue = Color(0xFFDFF5FF);
  static const Color lightPurple = Color(0xFFEDE6FF);
  static const Color lightGreen = Color(0xFFE9F8DD);
}

// ============================================================
// WELCOME
// ============================================================

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String childName = '';

  @override
  void initState() {
    super.initState();
    loadChild();
  }

  Future<void> loadChild() async {
    final child = await DatabaseHelper.instance.getActiveChild();

    if (!mounted) return;

    if (child != null) {
      setState(() {
        childName = child['name'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 18),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('☁️', style: TextStyle(fontSize: 45)),
                  Text('🌞', style: TextStyle(fontSize: 50)),
                ],
              ),

              const SizedBox(height: 5),

              Text(
                childName.isEmpty ? 'Welcome!' : 'Hi, $childName! 👋',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppColors.purple,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              const Text(
                'Learn • Play • Stay Safe',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),

              const SizedBox(height: 22),

              const LearningIllustration(),

              const SizedBox(height: 22),

              const Text(
                'A safe and fun place to learn',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),

              const Text(
                'new things every day! ❤️',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),

              const SizedBox(height: 24),

              ModeButton(
                title: 'Child',
                subtitle: "Let's Learn!",
                icon: '👦',
                color: AppColors.blue,
                onTap: () async {
                  final children = await DatabaseHelper.instance.getChildren();

                  if (!context.mounted) return;

                  if (children.isEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChildProfileScreen(),
                      ),
                    );
                  } else if (children.length == 1) {
                    await DatabaseHelper.instance.setActiveChild(
                      children.first['id'] as int,
                    );

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChildDashboard(
                          childName: children.first['name'] as String,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChildSelectionScreen(),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 13),

              ModeButton(
                title: 'Parent',
                subtitle: 'Secure Access',
                icon: '🔐',
                color: AppColors.purple,
                onTap: () {
                  showParentPinDialog(context);
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WELCOME ILLUSTRATION
// ============================================================

class LearningIllustration extends StatelessWidget {
  const LearningIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(150),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 22,
            left: 25,
            child: Text('⭐', style: TextStyle(fontSize: 25)),
          ),

          const Positioned(
            top: 38,
            right: 25,
            child: Text('⭐', style: TextStyle(fontSize: 22)),
          ),

          Positioned(
            top: 68,
            left: 15,
            child: FloatingLearningCard(text: 'ABC', color: AppColors.purple),
          ),

          Positioned(
            top: 70,
            right: 15,
            child: FloatingLearningCard(text: '📚', color: AppColors.green),
          ),

          Positioned(
            bottom: 72,
            left: 18,
            child: FloatingLearningCard(text: '123', color: AppColors.yellow),
          ),

          Positioned(
            bottom: 65,
            right: 18,
            child: FloatingLearningCard(text: '💡', color: AppColors.pink),
          ),

          const Positioned(
            top: 35,
            left: 0,
            right: 0,
            child: Text(
              '👦',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 130),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 7,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  '📖 Learn Something New!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FLOATING CARD
// ============================================================

class FloatingLearningCard extends StatelessWidget {
  final String text;
  final Color color;

  const FloatingLearningCard({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MODE BUTTON
// ============================================================

class ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const ModeButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Color(0x25000000),
                blurRadius: 9,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 13),

              Container(
                height: 56,
                width: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 29)),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 19,
              ),

              const SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CHILD SELECTION - MULTIPLE CHILD SUPPORT
// ============================================================

class ChildSelectionScreen extends StatefulWidget {
  const ChildSelectionScreen({super.key});

  @override
  State<ChildSelectionScreen> createState() => _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends State<ChildSelectionScreen> {
  List<Map<String, dynamic>> children = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadChildren();
  }

  Future<void> loadChildren() async {
    try {
      final session = await DatabaseHelper.instance.getAuthSession();
      final token = session?['access_token'];

      if (token is! String || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      // Get children from the backend. The API automatically filters
      // children by the currently logged-in parent's ID.
      final serverChildren = await AuthService.getChildren(token: token);

      // Keep the existing local SQLite records in sync so the rest of
      // the app can continue using its local active-child/progress flow.
      final localChildren = await DatabaseHelper.instance.getChildren();

      for (final serverChild in serverChildren) {
        final exists = localChildren.any(
          (localChild) =>
              localChild['name'] == serverChild.name &&
              localChild['age'] == serverChild.age,
        );

        if (!exists) {
          await DatabaseHelper.instance.createChild(
            name: serverChild.name,
            age: serverChild.age,
          );
        }
      }

      final data = await DatabaseHelper.instance.getChildren();

      if (!mounted) return;

      setState(() {
        children = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        children = [];
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> selectChild(Map<String, dynamic> child) async {
    await DatabaseHelper.instance.setActiveChild(child['id'] as int);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChildDashboard(childName: child['name'] as String),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Choose Your Profile 👧👦',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Who is learning today?',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: children.length,
                      itemBuilder: (context, index) {
                        final child = children[index];

                        return GestureDetector(
                          onTap: () => selectChild(child),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 64,
                                  width: 64,
                                  decoration: const BoxDecoration(
                                    color: AppColors.lightBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '👦',
                                      style: TextStyle(fontSize: 37),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      Text(
                                        'Age ${child['age']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppColors.purple,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChildProfileScreen(),
                          ),
                        );
                        loadChildren();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Child'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// CHILD PROFILE
// ============================================================

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final nameController = TextEditingController();

  int selectedAge = 8;
  String? error;
  bool saving = false;

  Future<void> saveProfile() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        error = 'Please enter your name';
      });
      return;
    }

    if (selectedAge < 5 || selectedAge > 13) {
      setState(() {
        error = 'Age must be between 5 and 13';
      });
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      // --------------------------------------------------------
      // GET CURRENT LOGIN SESSION
      // --------------------------------------------------------
      final session = await DatabaseHelper.instance.getAuthSession();
      final token = session?['access_token'];

      if (token is! String || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      // --------------------------------------------------------
      // SAVE CHILD TO PYTHON / FASTAPI SQLITE DATABASE
      // --------------------------------------------------------
      // The backend gets parent_id from the authenticated token.
      // Therefore one parent can never create a child for another parent.
      final serverChild = await AuthService.createChild(
        name: name,
        age: selectedAge,
        token: token,
      );

      print('CHILD SAVED TO SERVER');
      print('Server child ID: ${serverChild.id}');
      print('Server parent ID: ${serverChild.parentId}');
      print('Child name: ${serverChild.name}');
      print('Child age: ${serverChild.age}');

      // --------------------------------------------------------
      // KEEP LOCAL SQLITE IN SYNC
      // --------------------------------------------------------
      // The existing app uses local SQLite for active-child and
      // learning/progress data, so keep a local copy as well.
      final localChildId = await DatabaseHelper.instance.createChild(
        name: serverChild.name,
        age: serverChild.age,
      );

      await DatabaseHelper.instance.setActiveChild(localChildId);

      // --------------------------------------------------------
      // INITIAL PROGRESS
      // --------------------------------------------------------
      await DatabaseHelper.instance.saveLearningProgress(
        subject: 'Math',
        lessonsCompleted: 0,
        stars: 0,
      );

      await DatabaseHelper.instance.saveLearningProgress(
        subject: 'English',
        lessonsCompleted: 0,
        stars: 0,
      );

      await DatabaseHelper.instance.saveLearningProgress(
        subject: 'Science',
        lessonsCompleted: 0,
        stars: 0,
      );

      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name added successfully! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChildDashboard(childName: serverChild.name),
        ),
      );
    } catch (e) {
      print('CREATE CHILD ERROR: $e');

      if (!mounted) return;

      setState(() {
        saving = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Create Your Profile 🌟',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              height: 115,
              width: 115,
              decoration: const BoxDecoration(
                color: AppColors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('👦', style: TextStyle(fontSize: 70)),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Let’s get started!',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tell us a little about you.',
              style: TextStyle(color: AppColors.navy),
            ),

            const SizedBox(height: 28),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How old are you?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(9, (index) {
                      final age = index + 5;

                      final selected = selectedAge == age;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAge = age;
                          });
                        },
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.purple : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '$age',
                              style: TextStyle(
                                color: selected ? Colors.white : AppColors.navy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            if (error != null)
              Text(
                error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Start Learning 🚀',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHILD DASHBOARD
// ============================================================

class ChildDashboard extends StatelessWidget {
  final String childName;

  const ChildDashboard({super.key, required this.childName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(
          'Hi, $childName! 👋',
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 44)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to learn, $childName?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose something fun today!',
                          style: TextStyle(color: AppColors.navy, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'What do you want to do?',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),

            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.12,
              children: [
                FeatureCard(
                  icon: '🤖',
                  title: 'AI Tutor',
                  color: AppColors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiTutorScreen()),
                    );
                  },
                ),

                FeatureCard(
                  icon: '📚',
                  title: 'Learning',
                  color: AppColors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LearningScreen()),
                    );
                  },
                ),

                FeatureCard(
                  icon: '🧠',
                  title: 'Daily Quiz',
                  color: AppColors.yellow,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyQuizScreen(),
                      ),
                    );
                  },
                ),

                FeatureCard(
                  icon: '🏆',
                  title: 'My Progress',
                  color: AppColors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgressScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChildSafetyScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Text('🛡️', style: TextStyle(fontSize: 31)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I Need Help',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Talk to a trusted adult',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FEATURE CARD
// ============================================================

class FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 43)),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LEARNING
// ============================================================

/*class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          '📚 Learn',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Column(
                children: [
                  Text('🚀', style: TextStyle(fontSize: 52)),
                  SizedBox(height: 8),
                  Text(
                    'What do you want to learn?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Pick a subject and start learning!',
                    style: TextStyle(color: AppColors.navy),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Subjects',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),

            const SizedBox(height: 14),

            LearningSubjectCard(
              icon: '🔢',
              title: 'Math',
              subtitle: 'Numbers, counting & fun problems',
              color: AppColors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LearningScreen(),
                  ),
                );
              },
            ),
            LearningSubjectCard(
              icon: '📖',
              title: 'English',
              subtitle: 'Words, spelling & reading',
              color: AppColors.blue,
              onTap: () => showLesson(context, 'English'),
            ),

            LearningSubjectCard(
              icon: '🔬',
              title: 'Science',
              subtitle: 'Animals, nature & our world',
              color: AppColors.green,
              onTap: () => showLesson(context, 'Science'),
            ),

            LearningSubjectCard(
              icon: '🌍',
              title: 'General Knowledge',
              subtitle: 'Interesting things around us',
              color: AppColors.yellow,
              onTap: () => showLesson(context, 'General Knowledge'),
            ),
          ],
        ),
      ),
    );
  }
}*/

// ============================================================
// LEARNING SUBJECT CARD
// ============================================================

/*class LearningSubjectCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const LearningSubjectCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 30)),
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}*/

// ============================================================
// LESSON
// ============================================================

void showLesson(BuildContext context, String subject) {
  String emoji;
  String text;

  switch (subject) {
    case 'Math':
      emoji = '🔢';
      text = 'Numbers are everywhere! Try counting objects around you.';
      break;
    case 'English':
      emoji = '📖';
      text = 'Words help us share our ideas. Let’s learn new words every day!';
      break;
    case 'Science':
      emoji = '🔬';
      text = 'Science helps us understand animals, plants, space and nature.';
      break;
    default:
      emoji = '🌍';
      text = 'The world is full of amazing facts. Keep asking questions!';
  }

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(
          '$emoji $subject',
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          text,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await DatabaseHelper.instance.saveLearningProgress(
                subject: subject,
                lessonsCompleted: 1,
                stars: 1,
              );

              if (!context.mounted) return;

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⭐ Lesson completed!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Complete ⭐'),
          ),
        ],
      );
    },
  );
}

// ============================================================
// QUIZ
// ============================================================

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

const List<QuizQuestion> quizQuestions = [
  QuizQuestion(
    question: 'What is 2 + 3?',
    options: ['4', '5', '6', '7'],
    correctAnswer: 1,
  ),
  QuizQuestion(
    question: 'Which animal says "Moo"?',
    options: ['Cat', 'Dog', 'Cow', 'Lion'],
    correctAnswer: 2,
  ),
  QuizQuestion(
    question: 'What color is the sky on a clear day?',
    options: ['Blue', 'Green', 'Pink', 'Black'],
    correctAnswer: 0,
  ),
  QuizQuestion(
    question: 'How many legs does a spider have?',
    options: ['4', '6', '8', '10'],
    correctAnswer: 2,
  ),
  QuizQuestion(
    question: 'Which planet do we live on?',
    options: ['Mars', 'Earth', 'Jupiter', 'Venus'],
    correctAnswer: 1,
  ),
];

// ============================================================
// DAILY QUIZ SCREEN
// ============================================================

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  int? selectedAnswer;
  bool answered = false;
  bool saving = false;

  void selectAnswer(int index) {
    if (answered) return;

    setState(() {
      selectedAnswer = index;
      answered = true;

      if (index == quizQuestions[currentQuestion].correctAnswer) {
        score++;
      }
    });
  }

  Future<void> nextQuestion() async {
    if (currentQuestion < quizQuestions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      await showQuizResult();
    }
  }

  Future<void> showQuizResult() async {
    setState(() {
      saving = true;
    });

    await DatabaseHelper.instance.saveQuizScore(
      score: score,
      total: quizQuestions.length,
    );

    setState(() {
      saving = false;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Text(
            '🎉 Quiz Complete!',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 8),
              Text(
                '$score / ${quizQuestions.length}',
                style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                score >= 4 ? 'Amazing! 🌟' : 'Good job! Keep learning! 💪',
                style: const TextStyle(fontSize: 15, color: AppColors.navy),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = quizQuestions[currentQuestion];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          '🧠 Daily Quiz',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentQuestion + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  '${currentQuestion + 1}/${quizQuestions.length}',
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: (currentQuestion + 1) / quizQuestions.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.grey.shade200,
              color: AppColors.purple,
            ),

            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                question.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ),

            const SizedBox(height: 22),

            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedAnswer == index;

                  final isCorrect = index == question.correctAnswer;

                  Color cardColor = Colors.white;

                  if (answered && isCorrect) {
                    cardColor = AppColors.green;
                  } else if (answered && isSelected && !isCorrect) {
                    cardColor = AppColors.pink;
                  }

                  return GestureDetector(
                    onTap: () => selectAnswer(index),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 35,
                            width: 35,
                            decoration: const BoxDecoration(
                              color: AppColors.lightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              question.options[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: answered ? Colors.white : AppColors.navy,
                              ),
                            ),
                          ),
                          if (answered && isCorrect)
                            const Text(
                              '✓',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: saving ? null : nextQuestion,
                  child: saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          currentQuestion == quizQuestions.length - 1
                              ? 'See Result ⭐'
                              : 'Next Question →',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROGRESS SCREEN - REAL SQLITE DATA
// ============================================================

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int quizAttempts = 0;
  int totalStars = 0;
  int totalLessons = 0;
  double quizAverage = 0;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final scores = await DatabaseHelper.instance.getQuizScores();

    final progress = await DatabaseHelper.instance.getLearningProgress();

    int stars = 0;
    int lessons = 0;

    for (final item in progress) {
      stars += (item['stars'] as int?) ?? 0;

      lessons += (item['lessons_completed'] as int?) ?? 0;
    }

    double average = 0;

    if (scores.isNotEmpty) {
      int totalPercent = 0;

      for (final item in scores) {
        final score = item['score'] as int;
        final total = item['total'] as int;

        if (total > 0) {
          totalPercent += ((score / total) * 100).round();
        }
      }

      average = totalPercent / scores.length;
    }

    if (!mounted) return;

    setState(() {
      quizAttempts = scores.length;
      totalStars = stars;
      totalLessons = lessons;
      quizAverage = average;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          '🏆 My Progress',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadProgress,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.lightPurple,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Column(
                  children: [
                    Text('🌟', style: TextStyle(fontSize: 58)),
                    SizedBox(height: 8),
                    Text(
                      'Great job, Learner!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Keep learning every day!',
                      style: TextStyle(color: AppColors.navy),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: ProgressCard(
                      icon: '⭐',
                      value: '$totalStars',
                      title: 'Stars',
                      color: AppColors.yellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProgressCard(
                      icon: '🧠',
                      value: '$quizAttempts',
                      title: 'Quizzes',
                      color: AppColors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ProgressCard(
                      icon: '📚',
                      value: '$totalLessons',
                      title: 'Lessons',
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProgressCard(
                      icon: '🎯',
                      value: '${quizAverage.round()}%',
                      title: 'Quiz Avg.',
                      color: AppColors.pink,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learning Goal 🎯',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: totalLessons > 0
                          ? (totalLessons / 10).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.green,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$totalLessons / 10 lessons completed',
                      style: const TextStyle(color: AppColors.navy),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROGRESS CARD
// ============================================================

class ProgressCard extends StatelessWidget {
  final String icon;
  final String value;
  final String title;
  final Color color;

  const ProgressCard({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 33)),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHILD SAFETY
// ============================================================

class ChildSafetyScreen extends StatelessWidget {
  const ChildSafetyScreen({super.key});

  Future<void> createHelpRequest(BuildContext context, String type) async {
    await DatabaseHelper.instance.createSafetyRequest(
      type: type,
      message: 'Child requested help through SafeLearn.',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💙 Your trusted adult has been notified.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Safety Center 🛡️',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Column(
                children: [
                  Text('🛡️', style: TextStyle(fontSize: 60)),
                  SizedBox(height: 8),
                  Text(
                    'You are not alone',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'If something makes you uncomfortable, '
                    'you can always ask a trusted adult for help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.navy,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SafetyActionCard(
              icon: '🚨',
              title: 'I Need Help Now',
              subtitle: 'I feel unsafe or scared',
              color: AppColors.pink,
              onTap: () async {
                await createHelpRequest(context, 'need_help');
              },
            ),

            SafetyActionCard(
              icon: '👨‍👩‍👧',
              title: 'Contact My Parent',
              subtitle: 'Tell my trusted adult',
              color: AppColors.blue,
              onTap: () async {
                await createHelpRequest(context, 'contact_parent');
              },
            ),

            SafetyActionCard(
              icon: '💬',
              title: 'Someone Is Bothering Me',
              subtitle: 'I want to tell someone',
              color: AppColors.purple,
              onTap: () async {
                await createHelpRequest(context, 'someone_bothering_me');
              },
            ),

            SafetyActionCard(
              icon: '❤️',
              title: 'I Just Want To Talk',
              subtitle: 'I need someone I trust',
              color: AppColors.green,
              onTap: () async {
                await createHelpRequest(context, 'want_to_talk');
              },
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌟 Remember',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• Never share your password or private information.',
                    style: TextStyle(color: AppColors.navy, height: 1.5),
                  ),
                  Text(
                    '• If something feels wrong, tell a trusted adult.',
                    style: TextStyle(color: AppColors.navy, height: 1.5),
                  ),
                  Text(
                    '• You can always ask for help.',
                    style: TextStyle(color: AppColors.navy, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SAFETY CARD
// ============================================================

class SafetyActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const SafetyActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 27)),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PARENT PIN
// ============================================================

void showParentPinDialog(BuildContext context) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return ParentPinDialog(
        controller: controller,
        dialogContext: dialogContext,
      );
    },
  );
}

class ParentPinDialog extends StatefulWidget {
  final TextEditingController controller;
  final BuildContext dialogContext;

  const ParentPinDialog({
    super.key,
    required this.controller,
    required this.dialogContext,
  });

  @override
  State<ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends State<ParentPinDialog> {
  String? error;
  bool checking = false;

  Future<void> login() async {
    setState(() {
      checking = true;
      error = null;
    });

    final session = await DatabaseHelper.instance.getAuthSession();
    final token = session?['access_token'];
    if (token is! String) {
      setState(() {
        checking = false;
        error = 'Login session not found';
      });
      return;
    }

    bool isValid = false;
    try {
      await AuthService.verifyPin(pin: widget.controller.text, token: token);
      isValid = true;
    } catch (_) {
      isValid = false;
    }

    if (!mounted) return;

    if (isValid) {
      Navigator.pop(widget.dialogContext);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParentDashboard()),
      );
    } else {
      setState(() {
        checking = false;
        error = 'Incorrect PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: const Text(
        '🔐 Parent Access',
        style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your 4-digit PIN'),

          const SizedBox(height: 14),

          TextField(
            controller: widget.controller,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '••••',
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (error != null)
            Text(
              error!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: checking
              ? null
              : () {
                  Navigator.pop(widget.dialogContext);
                },
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
          ),
          onPressed: checking ? null : login,
          child: checking
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Continue'),
        ),
      ],
    );
  }
}

// ============================================================
// PARENT DASHBOARD
// ============================================================

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  Map<String, dynamic>? child;
  int quizAttempts = 0;
  int safetyRequests = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final childData = await DatabaseHelper.instance.getChild();

    final scores = await DatabaseHelper.instance.getQuizScores();

    final safety = await DatabaseHelper.instance.getSafetyRequests();

    if (!mounted) return;

    setState(() {
      child = childData;
      quizAttempts = scores.length;
      safetyRequests = safety.where((item) => item['status'] == 'new').length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Parent Dashboard 👨‍👩‍👧',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: AppColors.navy),
            onPressed: () async {
              await DatabaseHelper.instance.clearAuthSession();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChildSelectionScreen(),
                    ),
                  );
                  await loadDashboard();
                },
                onLongPress: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChildProfileScreen(),
                    ),
                  );
                  await loadDashboard();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: AppColors.lightPurple,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Text('👦', style: TextStyle(fontSize: 43)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child == null
                                  ? 'Child Profile'
                                  : '${child!['name']} • Age ${child!['age']}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                            const Text(
                              'Learning & Safety Overview',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: SmallStatCard(
                      icon: '🧠',
                      value: '$quizAttempts',
                      title: 'Quizzes',
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SmallStatCard(
                      icon: '🚨',
                      value: '$safetyRequests',
                      title: 'New Alerts',
                      color: AppColors.pink,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 360,
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    FeatureCard(
                      icon: '📊',
                      title: 'Progress',
                      color: AppColors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProgressScreen(),
                          ),
                        );
                      },
                    ),

                    FeatureCard(
                      icon: '🛡️',
                      title: 'Safety',
                      color: AppColors.pink,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ParentSafetyScreen(),
                          ),
                        );

                        loadDashboard();
                      },
                    ),

                    FeatureCard(
                      icon: '⏰',
                      title: 'Screen Time',
                      color: AppColors.green,
                      onTap: () {
                        showScreenTimeDialog(context);
                      },
                    ),

                    FeatureCard(
                      icon: '⚙️',
                      title: 'Settings',
                      color: AppColors.purple,
                      onTap: () {
                        showComingSoon(context, 'Settings');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SMALL STAT
// ============================================================

class SmallStatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String title;
  final Color color;

  const SmallStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PARENT SAFETY
// ============================================================

class ParentSafetyScreen extends StatefulWidget {
  const ParentSafetyScreen({super.key});

  @override
  State<ParentSafetyScreen> createState() => _ParentSafetyScreenState();
}

class _ParentSafetyScreenState extends State<ParentSafetyScreen> {
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    final data = await DatabaseHelper.instance.getSafetyRequests();

    if (!mounted) return;

    setState(() {
      requests = data;
    });
  }

  Future<void> markHandled(int id) async {
    await DatabaseHelper.instance.markSafetyRequestHandled(id);

    await loadRequests();
  }

  String readableType(String type) {
    switch (type) {
      case 'need_help':
        return '🚨 Child requested help';

      case 'contact_parent':
        return '👨‍👩‍👧 Child wants parent';

      case 'someone_bothering_me':
        return '💬 Someone may be bothering child';

      case 'want_to_talk':
        return '❤️ Child wants to talk';

      default:
        return '🛡️ Safety request';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Safety Center 🛡️',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadRequests,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Text('🛡️', style: TextStyle(fontSize: 43)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safety Monitoring',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        '${requests.where((r) => r['status'] == 'new').length} new request(s)',
                        style: const TextStyle(color: AppColors.navy),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (requests.isEmpty)
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text('✅', style: TextStyle(fontSize: 55)),
                    SizedBox(height: 10),
                    Text(
                      'No safety requests yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),

            ...requests.map((request) {
              final id = request['id'] as int;

              final isNew = request['status'] == 'new';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: isNew ? AppColors.lightPurple : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      readableType(request['type'] as String),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      request['message'] as String? ?? '',
                      style: const TextStyle(color: AppColors.navy),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      request['created_at'] as String,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),

                    if (isNew)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => markHandled(id),
                          child: const Text('Mark Handled ✓'),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SCREEN TIME
// ============================================================

void showScreenTimeDialog(BuildContext context) {
  int selectedMinutes = 60;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: const Text(
              '⏰ Screen Time',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Daily screen-time limit'),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  initialValue: selectedMinutes,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 minutes')),
                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                    DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                    DropdownMenuItem(value: 120, child: Text('2 hours')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMinutes = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await DatabaseHelper.instance.updateScreenTime(
                    selectedMinutes,
                  );

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⏰ Limit saved: $selectedMinutes minutes'),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ============================================================
// AI TUTOR
// ============================================================

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController controller = TextEditingController();

  final List<ChatMessage> messages = [
    const ChatMessage(
      text:
          "Hi! 👋 I'm your Learning Buddy. What would you like to learn today?",
      isAi: true,
    ),
  ];

  void sendMessage() {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: text, isAi: false));
    });

    controller.clear();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() {
        messages.add(
          const ChatMessage(
            text: "That's a great question! 🌟 Let's learn it together!",
            isAi: true,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Row(
          children: [
            Text('🤖', style: TextStyle(fontSize: 27)),
            SizedBox(width: 8),
            Text(
              'AI Tutor',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              scrollDirection: Axis.horizontal,
              children: [
                SubjectChip(
                  icon: '🧮',
                  title: 'Math',
                  color: AppColors.purple,
                  onTap: () {
                    controller.text = 'I want to learn Math';
                    sendMessage();
                  },
                ),
                SubjectChip(
                  icon: '📖',
                  title: 'English',
                  color: AppColors.blue,
                  onTap: () {
                    controller.text = 'I want to learn English';
                    sendMessage();
                  },
                ),
                SubjectChip(
                  icon: '🔬',
                  title: 'Science',
                  color: AppColors.green,
                  onTap: () {
                    controller.text = 'I want to learn Science';
                    sendMessage();
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: messages[index]);
              },
            ),
          ),

          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎤 Voice Tutor will be added later.'),
                ),
              );
            },
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Ask with your voice'),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        sendMessage();
                      },
                      decoration: InputDecoration(
                        hintText: 'Ask me something...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap: sendMessage,
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAT
// ============================================================

class ChatMessage {
  final String text;
  final bool isAi;

  const ChatMessage({required this.text, required this.isAi});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: message.isAi ? AppColors.lightPurple : AppColors.blue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isAi) ...[
              const Text('🤖', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isAi ? AppColors.navy : Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectChip extends StatelessWidget {
  final String icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const SubjectChip({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 19)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HELPER
// ============================================================

void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature module will be added next 🚀'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
