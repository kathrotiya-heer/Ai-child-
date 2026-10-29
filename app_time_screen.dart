import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTimeScreen extends StatefulWidget {
  const AppTimeScreen({super.key});

  @override
  State<AppTimeScreen> createState() => _AppTimeScreenState();
}

class _AppTimeScreenState extends State<AppTimeScreen> {
  // ============================================================
  // CHANNELS
  // ============================================================

  static const MethodChannel _storageChannel = MethodChannel(
    'child_safety/storage',
  );

  static const MethodChannel _appChannel = MethodChannel('child_safety/apps');

  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _minutesController = TextEditingController();

  // ============================================================
  // APP DATA
  // ============================================================

  List<Map<String, String>> _apps = [];

  final Map<String, int> _appTimeLimits = <String, int>{};

  String? _selectedPackage;

  bool _loadingApps = true;
  bool _loadingLimits = true;
  bool _saving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _minutesController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD EVERYTHING
  // ============================================================

  Future<void> _loadData() async {
    await _loadSavedTimeLimits();

    await _loadInstalledApps();
  }

  // ============================================================
  // LOAD SAVED LIMITS
  // ============================================================

  Future<void> _loadSavedTimeLimits() async {
    try {
      setState(() {
        _loadingLimits = true;
      });

      final result = await _storageChannel.invokeMethod('getAppTimeLimits');

      final Map<String, int> loadedLimits = <String, int>{};

      if (result is Map) {
        result.forEach((key, value) {
          final packageName = key.toString();

          final minutes = int.tryParse(value.toString());

          if (packageName.isNotEmpty && minutes != null && minutes > 0) {
            loadedLimits[packageName] = minutes;
          }
        });
      }

      if (!mounted) return;

      setState(() {
        _appTimeLimits.clear();

        _appTimeLimits.addAll(loadedLimits);

        _loadingLimits = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingLimits = false;
      });

      _showMessage('Unable to load saved time limits: $e');
    }
  }

  // ============================================================
  // LOAD INSTALLED APPS
  // ============================================================

  Future<void> _loadInstalledApps() async {
    try {
      final result = await _appChannel.invokeMethod('getInstalledApps');

      final List<Map<String, String>> loadedApps = <Map<String, String>>[];

      if (result is List) {
        for (final item in result) {
          if (item is Map) {
            final name = item['name']?.toString() ?? '';

            final packageName = item['packageName']?.toString() ?? '';

            if (name.isNotEmpty && packageName.isNotEmpty) {
              loadedApps.add({'name': name, 'packageName': packageName});
            }
          }
        }
      }

      loadedApps.sort((a, b) {
        return a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase());
      });

      if (!mounted) return;

      setState(() {
        _apps = loadedApps;

        _loadingApps = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingApps = false;
      });

      _showMessage('Unable to load installed apps: $e');
    }
  }

  // ============================================================
  // SAVE SELECTED APP TIME
  // ============================================================

  Future<void> _saveSelectedAppTime() async {
    // ----------------------------------------------------------
    // CHECK APP
    // ----------------------------------------------------------

    if (_selectedPackage == null || _selectedPackage!.isEmpty) {
      _showMessage('Please select an app');

      return;
    }

    // ----------------------------------------------------------
    // GET MINUTES
    // ----------------------------------------------------------

    final minutes = int.tryParse(_minutesController.text.trim());

    // ==========================================================
    // NEW:
    // 0 = NO LIMIT
    // ==========================================================

    if (minutes == null || minutes < 0) {
      _showMessage('Enter 0 for No Limit or enter a valid time');

      return;
    }

    // ----------------------------------------------------------
    // PREVENT DOUBLE SAVE
    // ----------------------------------------------------------

    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // --------------------------------------------------------
      // SAVE TO ANDROID
      // --------------------------------------------------------

      final success = await _storageChannel.invokeMethod('saveSingleAppTime', {
        'packageName': _selectedPackage,
        'minutes': minutes,
      });

      // --------------------------------------------------------
      // SAVE SUCCESS
      // --------------------------------------------------------

      if (success == true) {
        if (mounted) {
          setState(() {
            if (minutes == 0) {
              // =================================================
              // NEW:
              // NO LIMIT -> REMOVE FROM UI LIMIT LIST
              // =================================================

              _appTimeLimits.remove(_selectedPackage!);
            } else {
              _appTimeLimits[_selectedPackage!] = minutes;
            }
          });
        }

        // ------------------------------------------------------
        // READ BACK FROM ANDROID
        // ------------------------------------------------------

        final verifyResult = await _storageChannel.invokeMethod(
          'getAppTimeLimits',
        );

        bool found = false;

        if (verifyResult is Map) {
          final savedValue = verifyResult[_selectedPackage];

          final savedMinutes = int.tryParse(savedValue?.toString() ?? '');

          if (minutes == 0) {
            // =================================================
            // NO LIMIT IS SUCCESSFUL IF APP IS NOT IN LIMIT MAP
            // =================================================

            found = savedMinutes == null;
          } else {
            found = savedMinutes == minutes;
          }
        } else if (minutes == 0) {
          // ===================================================
          // EMPTY MAP ALSO MEANS NO LIMIT
          // ===================================================

          found = true;
        }

        if (!mounted) return;

        if (found) {
          if (minutes == 0) {
            _showMessage('No limit set successfully');
          } else {
            _showMessage('Time limit saved successfully');
          }
        } else {
          _showMessage('Save verification failed');
        }
      } else {
        if (!mounted) return;

        _showMessage('Unable to save time limit');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

      _showMessage('Save error: ${e.code} ${e.message}');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Save error: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });
    }
  }

  // ============================================================
  // REMOVE TIME LIMIT
  // ============================================================

  Future<void> _removeTimeLimit(String packageName) async {
    try {
      final success = await _storageChannel.invokeMethod(
        'removeSingleAppTime',
        {'packageName': packageName},
      );

      if (success == true) {
        if (!mounted) return;

        setState(() {
          _appTimeLimits.remove(packageName);

          if (_selectedPackage == packageName) {
            _selectedPackage = null;

            _minutesController.clear();
          }
        });

        _showMessage('Time limit removed');
      } else {
        _showMessage('Unable to remove time limit');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

      _showMessage('Remove error: ${e.code} ${e.message}');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to remove time limit: $e');
    }
  }

  // ============================================================
  // APP SELECTED
  // ============================================================

  void _onAppSelected(String? packageName) {
    if (packageName == null) {
      return;
    }

    final existingLimit = _appTimeLimits[packageName];

    setState(() {
      _selectedPackage = packageName;

      if (existingLimit != null) {
        _minutesController.text = existingLimit.toString();
      } else {
        // =====================================================
        // NO LIMIT / NO SAVED LIMIT
        // =====================================================

        _minutesController.clear();
      }
    });
  }

  // ============================================================
  // GET APP NAME
  // ============================================================

  String _getAppName(String packageName) {
    for (final app in _apps) {
      if (app['packageName'] == packageName) {
        return app['name'] ?? packageName;
      }
    }

    return packageName;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Time')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // ==================================================
            // SELECT APP
            // ==================================================
            if (_loadingApps)
              const Padding(
                padding: EdgeInsets.all(20),

                child: CircularProgressIndicator(),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedPackage,

                decoration: const InputDecoration(
                  labelText: 'Select App',

                  border: OutlineInputBorder(),
                ),

                items: _apps.map((app) {
                  return DropdownMenuItem<String>(
                    value: app['packageName'],

                    child: Text(
                      app['name'] ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),

                onChanged: _onAppSelected,
              ),

            const SizedBox(height: 20),

            // ==================================================
            // TIME INPUT
            // ==================================================
            TextField(
              controller: _minutesController,

              keyboardType: TextInputType.number,

              inputFormatters: [FilteringTextInputFormatter.digitsOnly],

              decoration: const InputDecoration(
                labelText: 'Daily Time Limit',

                hintText: 'Example: 30',

                suffixText: 'minutes',

                border: OutlineInputBorder(),

                helperText: 'Enter 0 for No Limit',
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SAVE BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: _saving ? null : _saveSelectedAppTime,

                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Time Limit'),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // TITLE
            // ==================================================
            const Align(
              alignment: Alignment.centerLeft,

              child: Text(
                'Saved App Time Limits',

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // SAVED LIMITS
            // ==================================================
            Expanded(
              child: _loadingLimits
                  ? const Center(child: CircularProgressIndicator())
                  : _appTimeLimits.isEmpty
                  ? const Center(child: Text('No time limits set'))
                  : ListView.builder(
                      itemCount: _appTimeLimits.length,

                      itemBuilder: (context, index) {
                        final packageName = _appTimeLimits.keys.elementAt(
                          index,
                        );

                        final minutes = _appTimeLimits[packageName]!;

                        return Card(
                          child: ListTile(
                            title: Text(_getAppName(packageName)),

                            subtitle: Text('$minutes minutes per day'),

                            trailing: IconButton(
                              icon: const Icon(Icons.delete),

                              onPressed: () {
                                _removeTimeLimit(packageName);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
