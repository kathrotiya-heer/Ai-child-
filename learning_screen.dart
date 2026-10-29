import 'package:flutter/material.dart';

// ============================================================
// COLORS
// ============================================================

class AppColors {
  static const Color cream = Color(0xFFFFF8E7);
  static const Color navy = Color(0xFF172B4D);
  static const Color purple = Color(0xFF7E57C2);
  static const Color blue = Color(0xFF42A5F5);
  static const Color green = Color(0xFF66BB6A);
  static const Color yellow = Color(0xFFFFCA28);
  static const Color pink = Color(0xFFFF80AB);
  static const Color orange = Color(0xFFFFA726);
  static const Color lightBlue = Color(0xFFE3F2FD);
}

// ============================================================
// LEARNING HOME
// ============================================================

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.navy,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '📚 Learn',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
      ),

      body: Stack(
        children: [
          const LearningBackground(),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HERO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7E57C2), Color(0xFFAA8CE3)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🚀', style: TextStyle(fontSize: 55)),
                      SizedBox(height: 12),
                      Text(
                        'Let’s Learn!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choose a subject and start your learning adventure!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  '📚 Subjects',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),

                const SizedBox(height: 17),

                LearningSubjectCard(
                  icon: '🔢',
                  title: 'Math',
                  subtitle: 'Numbers, counting & fun problems',
                  color: AppColors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MathLearningScreen(),
                      ),
                    );
                  },
                ),

                LearningSubjectCard(
                  icon: '📖',
                  title: 'English',
                  subtitle: 'Words, spelling & reading',
                  color: AppColors.blue,
                  onTap: () {},
                ),

                LearningSubjectCard(
                  icon: '🔬',
                  title: 'Science',
                  subtitle: 'Animals, nature & our world',
                  color: AppColors.green,
                  onTap: () {},
                ),

                LearningSubjectCard(
                  icon: '🌍',
                  title: 'General Knowledge',
                  subtitle: 'Interesting things around us',
                  color: AppColors.orange,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHILD FRIENDLY BACKGROUND
// ============================================================

class LearningBackground extends StatelessWidget {
  const LearningBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 25,
            right: -35,
            child: _circle(135, const Color(0xFFFFDDEB)),
          ),

          Positioned(
            top: 220,
            left: -45,
            child: _circle(110, const Color(0xFFD9F2FF)),
          ),

          Positioned(
            bottom: 80,
            right: -40,
            child: _circle(145, const Color(0xFFE2F6E5)),
          ),

          const Positioned(
            top: 90,
            right: 45,
            child: Text('⭐', style: TextStyle(fontSize: 25)),
          ),

          const Positioned(
            top: 330,
            right: 35,
            child: Text('✨', style: TextStyle(fontSize: 23)),
          ),

          const Positioned(
            bottom: 180,
            left: 25,
            child: Text('☁️', style: TextStyle(fontSize: 35)),
          ),

          const Positioned(
            bottom: 60,
            right: 80,
            child: Text('🌈', style: TextStyle(fontSize: 30)),
          ),
        ],
      ),
    );
  }

  static Widget _circle(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ============================================================
// SUBJECT CARD
// ============================================================

class LearningSubjectCard extends StatelessWidget {
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.20),
              blurRadius: 13,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 65,
              width: 65,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 34)),
              ),
            ),

            const SizedBox(width: 17),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MATH TOPICS
// ============================================================

class MathLearningScreen extends StatelessWidget {
  const MathLearningScreen({super.key});

  final List<Map<String, dynamic>> topics = const [
    {
      'title': 'Addition',
      'subtitle': 'Learn to add numbers',
      'icon': Icons.add_circle_rounded,
      'progress': 1.0,
    },
    {
      'title': 'Subtraction',
      'subtitle': 'Take numbers away',
      'icon': Icons.remove_circle_rounded,
      'progress': 0.75,
    },
    {
      'title': 'Fractions',
      'subtitle': 'Understand parts of a whole',
      'icon': Icons.pie_chart_rounded,
      'progress': 0.35,
    },
    {
      'title': 'Geometry',
      'subtitle': 'Shapes, lines and angles',
      'icon': Icons.category_rounded,
      'progress': 0.0,
    },
    {
      'title': 'Multiplication',
      'subtitle': 'Master multiplication',
      'icon': Icons.close_rounded,
      'progress': 0.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.navy,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          '🔢 Mathematics',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
      ),

      body: Stack(
        children: [
          const LearningBackground(),

          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7E57C2), Color(0xFFA78BDE)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    children: [
                      Text('🧮', style: TextStyle(fontSize: 50)),

                      SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Math Adventure',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 6),

                            Text(
                              'Pick a topic and start learning!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Choose a Topic',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    children: List.generate(topics.length, (index) {
                      final topic = topics[index];

                      return _topicCard(context, topic, index);
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicCard(
    BuildContext context,
    Map<String, dynamic> topic,
    int index,
  ) {
    final double progress = (topic['progress'] as num).toDouble();

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LessonLearningScreen(topic: topic['title'].toString()),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F8),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    topic['icon'] as IconData,
                    color: AppColors.purple,
                    size: 29,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic['title'].toString(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        topic['subtitle'].toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 9),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEDEAF1),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.purple,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        if (index != topics.length - 1) const Divider(height: 1),
      ],
    );
  }
}

// ============================================================
// FULL LESSON SCREEN
// ============================================================

class LessonLearningScreen extends StatefulWidget {
  final String topic;

  const LessonLearningScreen({super.key, required this.topic});

  @override
  State<LessonLearningScreen> createState() => _LessonLearningScreenState();
}

class _LessonLearningScreenState extends State<LessonLearningScreen> {
  int selectedLesson = 0;

  final List<String> lessonParts = [
    'Explanation',
    'Example',
    'Practice',
    'Quiz',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.navy,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          '📖 ${widget.topic}',
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: Stack(
        children: [
          const LearningBackground(),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 5, 15, 35),
            child: Column(
              children: [
                // ==========================================
                // PROGRESS
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 30)),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Learning Journey',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                                fontSize: 15,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Learn • Practice • Master',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '${selectedLesson + 1}/4',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 17),

                // ==========================================
                // MAIN FRAME
                // ==========================================
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ==================================
                        // LEFT MENU
                        // ==================================
                        Container(
                          width: 105,

                          padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),

                          decoration: const BoxDecoration(
                            color: Color(0xFFF0EBFA),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                          ),

                          child: Column(
                            children: [
                              const Text('🧒', style: TextStyle(fontSize: 38)),

                              const SizedBox(height: 18),

                              for (int i = 0; i < lessonParts.length; i++)
                                _sideButton(i, lessonParts[i]),
                            ],
                          ),
                        ),

                        // ==================================
                        // RIGHT CONTENT
                        // ==================================
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: _lessonDetail(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==========================================
                // NEXT
                // ==========================================
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedLesson < lessonParts.length - 1) {
                        setState(() {
                          selectedLesson++;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🎉 Amazing! You completed this lesson!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(19),
                      ),
                    ),
                    child: Text(
                      selectedLesson == lessonParts.length - 1
                          ? 'Finish Lesson 🎉'
                          : 'Next Lesson →',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LEFT MENU BUTTON
  // ==========================================================

  Widget _sideButton(int index, String title) {
    final bool selected = selectedLesson == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLesson = index;
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        width: double.infinity,

        margin: const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),

        decoration: BoxDecoration(
          color: selected ? AppColors.purple : Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.purple.withOpacity(0.25),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),

        child: Column(
          children: [
            Text(
              '${index + 1}',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.purple,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.navy,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LESSON CONTENT
  // ==========================================================

  Widget _lessonDetail() {
    switch (selectedLesson) {
      case 0:
        return _explanation();

      case 1:
        return _example();

      case 2:
        return _practice();

      case 3:
        return _quiz();

      default:
        return _explanation();
    }
  }

  // ==========================================================
  // EXPLANATION
  // ==========================================================

  Widget _explanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📖', style: TextStyle(fontSize: 48)),

        const SizedBox(height: 10),

        Text(
          '${widget.topic}',
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Let’s understand it step by step! 🧠',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.purple,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: const Color(0xFFEAF6FF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD2ECFF)),
          ),

          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🌟 What is it?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),

              SizedBox(height: 12),

              Text(
                'This lesson helps you understand the concept in a simple and fun way.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          '🧒 Easy Explanation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Imagine you are learning something new. We break the big idea into small steps so it becomes easy to understand. Read each step slowly and try to remember the important idea.',
          style: TextStyle(fontSize: 16, height: 1.75, color: Colors.black87),
        ),

        const SizedBox(height: 22),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5D8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⭐', style: TextStyle(fontSize: 30)),

              SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Remember: Understanding is more important than memorising!',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // EXAMPLE
  // ==========================================================

  Widget _example() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💡', style: TextStyle(fontSize: 48)),

        const SizedBox(height: 10),

        const Text(
          'Easy Example',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Let’s learn using a simple example! 👇',
          style: TextStyle(fontSize: 16, color: AppColors.purple),
        ),

        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),

          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF3CD), Color(0xFFFFE8A3)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),

          child: const Column(
            children: [
              Text('🍎  🍎  +  🍎  🍎', style: TextStyle(fontSize: 38)),

              SizedBox(height: 18),

              Text(
                '2 + 2 = 4',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'So the answer is 4! 🎉',
                style: TextStyle(fontSize: 17, color: AppColors.navy),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        _step('1', 'Look', 'Look carefully at the numbers or objects.'),

        _step('2', 'Think', 'Think about what the question is asking.'),

        _step('3', 'Solve', 'Use what you learned to find the answer.'),
      ],
    );
  }

  Widget _step(String number, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E2F2)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: AppColors.purple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PRACTICE
  // ==========================================================

  Widget _practice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('✏️', style: TextStyle(fontSize: 48)),

        const SizedBox(height: 10),

        const Text(
          'Practice Time!',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Now it’s your turn! 💪',
          style: TextStyle(fontSize: 16, color: AppColors.purple),
        ),

        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),

          decoration: BoxDecoration(
            color: const Color(0xFFF0EAFE),
            borderRadius: BorderRadius.circular(24),
          ),

          child: const Column(
            children: [
              Text('🍎 🍎 + 🍎 🍎', style: TextStyle(fontSize: 40)),

              SizedBox(height: 18),

              Text(
                'How many apples are there?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        Row(
          children: [
            _answerButton('2'),
            const SizedBox(width: 8),
            _answerButton('3'),
            const SizedBox(width: 8),
            _answerButton('4'),
          ],
        ),

        const SizedBox(height: 18),

        const Center(
          child: Text(
            '💡 Choose the correct answer',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _answerButton(String answer) {
    return Expanded(
      child: SizedBox(
        height: 55,
        child: OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  answer == '4' ? '🎉 Correct! Great job!' : '💪 Try again!',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },

          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.purple,
            side: const BorderSide(color: AppColors.purple, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),

          child: Text(
            answer,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // QUIZ
  // ==========================================================

  Widget _quiz() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🧠', style: TextStyle(fontSize: 48)),

        const SizedBox(height: 10),

        const Text(
          'Quick Quiz',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Let’s see what you remember! 🎯',
          style: TextStyle(fontSize: 16, color: AppColors.purple),
        ),

        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),

          decoration: BoxDecoration(
            color: const Color(0xFFE7F8EB),
            borderRadius: BorderRadius.circular(24),
          ),

          child: const Column(
            children: [
              Text('❓', style: TextStyle(fontSize: 40)),

              SizedBox(height: 12),

              Text(
                'What is 2 + 2?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _quizOption('A', '3'),
        _quizOption('B', '4'),
        _quizOption('C', '5'),
        _quizOption('D', '6'),
      ],
    );
  }

  Widget _quizOption(String letter, String answer) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),

      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                answer == '4'
                    ? '🎉 Excellent! Correct answer!'
                    : '💪 Not quite. Try again!',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },

        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),

          foregroundColor: AppColors.navy,

          side: const BorderSide(color: Color(0xFFE0DCE7), width: 1.5),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),

        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,

              decoration: const BoxDecoration(
                color: Color(0xFFEDE7F8),
                shape: BoxShape.circle,
              ),

              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Text(
              answer,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
