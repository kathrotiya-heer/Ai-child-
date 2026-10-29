import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScreenTimePage extends StatefulWidget {
  const ScreenTimePage({super.key});

  @override
  State<ScreenTimePage> createState() => _ScreenTimePageState();
}

enum SafetyLevel { safe, nearUnsafe, unsafe }

class _ScreenTimePageState extends State<ScreenTimePage>
    with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('screen_time');

  Duration _totalScreenTime = Duration.zero;
  List<Map<String, dynamic>> _appList = [];
  bool _loading = false;
  bool _hasPermission = false;
  bool _dataFetched = false;
  bool _isAppLocked = false; // App Lock Status

  // Daily Screen Time Target Limit (In Minutes) - Default: 120 mins (2 Hours)
  int _dailyLimitMinutes = 120;

  // Dummy 7-Day History Data
  final List<Map<String, dynamic>> _weeklyHistory = [
    {'day': 'Mon', 'minutes': 90},
    {'day': 'Tue', 'minutes': 110},
    {'day': 'Wed', 'minutes': 140}, // Unsafe
    {'day': 'Thu', 'minutes': 85},
    {'day': 'Fri', 'minutes': 105},
    {'day': 'Sat', 'minutes': 160}, // Unsafe
    {'day': 'Sun', 'minutes': 120},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionOnly();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionOnly();
    }
  }

  Future<void> _checkPermissionOnly() async {
    try {
      final bool hasPerm =
          await _channel.invokeMethod('checkPermission') ?? false;
      if (!mounted) return;
      setState(() {
        _hasPermission = hasPerm;
      });
    } catch (e) {
      debugPrint('Permission error: $e');
    }
  }

  Future<void> _fetchScreenTimeData() async {
    setState(() {
      _loading = true;
    });

    try {
      final bool hasPerm =
          await _channel.invokeMethod('checkPermission') ?? false;

      setState(() {
        _hasPermission = hasPerm;
      });

      if (!hasPerm) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'getScreenTimeData',
      );

      if (result != null && mounted) {
        final int totalMs = result['totalTimeMs'] as int? ?? 0;
        final List<dynamic> rawApps = result['appList'] as List<dynamic>? ?? [];

        final List<Map<String, dynamic>> parsedApps = rawApps.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return map;
        }).toList();

        setState(() {
          _totalScreenTime = Duration(milliseconds: totalMs);
          _appList = parsedApps;
          _loading = false;
          _dataFetched = true;
        });

        _checkAndTriggerAlertNotification();
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _checkAndTriggerAlertNotification() {
    final level = _calculateSafetyLevel();
    String message = '';

    if (level == SafetyLevel.nearUnsafe) {
      message = '⚠️ Warning: Child is reaching daily limit (80%+ used)!';
    } else if (level == SafetyLevel.unsafe) {
      message = '🚨 Alert: Daily Screen Time Limit Exceeded!';
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: level == SafetyLevel.unsafe
              ? Colors.red
              : Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _openPermissionSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } catch (e) {
      debugPrint('Open settings error: $e');
    }
  }

  void _toggleRemoteAppLock() {
    setState(() {
      _isAppLocked = !_isAppLocked;
    });

    final statusMsg = _isAppLocked
        ? '🔒 Remote Lock Activated on Child\'s Device!'
        : '🔓 Child\'s Device Unlocked!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(statusMsg),
        backgroundColor: _isAppLocked ? Colors.red.shade700 : Colors.green,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  SafetyLevel _calculateSafetyLevel() {
    final int usedMinutes = _totalScreenTime.inMinutes;
    if (usedMinutes >= _dailyLimitMinutes) {
      return SafetyLevel.unsafe;
    } else if (usedMinutes >= (_dailyLimitMinutes * 0.8)) {
      return SafetyLevel.nearUnsafe;
    } else {
      return SafetyLevel.safe;
    }
  }

  @override
  Widget build(BuildContext context) {
    final SafetyLevel currentLevel = _calculateSafetyLevel();

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Screen Time & Security',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_hasPermission) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.amber.shade900,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usage Permission Needed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const Text(
                            'Allow access to calculate real app usage.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _openPermissionSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Allow'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // FETCH BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _fetchScreenTimeData,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  _loading ? 'Fetching Analytics...' : 'Sync Live Screen Time',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_dataFetched) ...[
              // ALERT STATUS CARD (SAFE / NEAR UNSAFE / UNSAFE)
              _buildAlertCard(currentLevel),

              const SizedBox(height: 16),

              // FEATURE 1: REMOTE APP LOCK CONTROL BUTTON
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isAppLocked ? Icons.lock : Icons.lock_open,
                          color: _isAppLocked ? Colors.red : Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remote Device Controls',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _isAppLocked
                                  ? 'Device is Locked'
                                  : 'Device is Unlocked',
                              style: TextStyle(
                                color: _isAppLocked ? Colors.red : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _toggleRemoteAppLock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAppLocked
                            ? Colors.green
                            : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isAppLocked ? 'Unlock' : 'Lock Now'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // TOTAL SCREEN TIME DISPLAY CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 40,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_totalScreenTime),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daily Limit: $_dailyLimitMinutes Mins',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_totalScreenTime.inMinutes / _dailyLimitMinutes)
                            .clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: currentLevel == SafetyLevel.safe
                            ? Colors.green
                            : currentLevel == SafetyLevel.nearUnsafe
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // FEATURE 2: 7-DAY USAGE HISTORY GRAPH / TRENDS
              const Text(
                'Weekly Usage Trends (7 Days)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _weeklyHistory.map((item) {
                    final int mins = item['minutes'] as int;
                    final bool isOver = mins >= _dailyLimitMinutes;
                    final double heightRatio = (mins / 180).clamp(0.2, 1.0);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${mins}m',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 14,
                          height: 80 * heightRatio,
                          decoration: BoxDecoration(
                            color: isOver ? Colors.red : Colors.blue.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['day'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 25),

              // APP WISE USAGE BREAKDOWN
              const Text(
                'Apps Usage Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (_appList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No app usage recorded for today yet.'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _appList.length,
                  itemBuilder: (context, index) {
                    final item = _appList[index];
                    final String appName = item['appName'] as String;
                    final String packageName = item['packageName'] as String;
                    final int usageMs = item['usageTimeMs'] as int;
                    final Duration duration = Duration(milliseconds: usageMs);

                    final double percentage =
                        _totalScreenTime.inMilliseconds > 0
                        ? (usageMs / _totalScreenTime.inMilliseconds)
                        : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Text(
                                  appName.isNotEmpty
                                      ? appName[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      packageName,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade100,
                              color: Colors.blue.shade400,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(SafetyLevel level) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    switch (level) {
      case SafetyLevel.safe:
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle_outline;
        title = 'Safe Usage Zone';
        subtitle = 'Child\'s screen time is within healthy daily limits.';
        break;
      case SafetyLevel.nearUnsafe:
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade300;
        textColor = Colors.orange.shade900;
        icon = Icons.warning_amber_rounded;
        title = 'Near Unsafe (Warning)';
        subtitle = 'Screen time is reaching close to the daily limit!';
        break;
      case SafetyLevel.unsafe:
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        textColor = Colors.red.shade900;
        icon = Icons.gpp_bad_outlined;
        title = 'Unsafe Usage Alert!';
        subtitle = 'Daily limit exceeded! Tap Lock Below to restrict device.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
