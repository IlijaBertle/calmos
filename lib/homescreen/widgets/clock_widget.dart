import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart'; // Für Datum/Zeit
import 'package:intl/date_symbol_data_local.dart'; // Für deutsche Formatierung
import 'package:battery_plus/battery_plus.dart'; // Für den Akku

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  // --- Zeit & Datum ---
  String _timeString = "00:00";
  String _dateString = "";

  // --- Akku ---
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  // --- Styling Einstellungen ---
  Color _color = Colors.white;
  double _fontSize = 80;
  String _currentFont = 'default';
  bool _enableGlow = true;

  final List<String> _fontOptions = ['default', 'pixel', 'serif', 'mono'];

  @override
  void initState() {
    super.initState();

    // 1. Deutsches Datumsformat initialisieren
    initializeDateFormatting('de_DE', null).then((_) {
      if (mounted) {
        _updateTime();
      }
    });

    _initBattery();

    // Timer startet
    Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;

    final DateTime now = DateTime.now();
    setState(() {
      _timeString = DateFormat('HH:mm').format(now);
      try {
        _dateString = DateFormat('EEEE, d. MMMM', 'de_DE').format(now);
      } catch (e) {
        _dateString = "${now.day}.${now.month}.";
      }
    });
  }

  Future<void> _initBattery() async {
    try {
      final level = await _battery.batteryLevel;
      setState(() {
        _batteryLevel = level;
      });

      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        BatteryState state,
      ) async {
        final level = await _battery.batteryLevel;
        if (mounted) {
          setState(() {
            _batteryState = state;
            _batteryLevel = level;
          });
        }
      });
    } catch (e) {
      debugPrint("Batterie-Status konnte nicht geladen werden: $e");
    }
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    super.dispose();
  }

  // --- Dialog für Einstellungen ---
  void _openStyleDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Launcher Style",
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 1. Farbe
                  const Text(
                    "Akzentfarbe",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _colorOption(Colors.white, setModalState),
                      _colorOption(Colors.cyanAccent, setModalState),
                      _colorOption(Colors.purpleAccent, setModalState),
                      _colorOption(Colors.greenAccent, setModalState),
                      _colorOption(Colors.orangeAccent, setModalState),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 2. Größe
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Größe",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        "${_fontSize.round()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 40,
                    max: 120,
                    thumbColor: _color,
                    activeColor: _color,
                    inactiveColor: Colors.grey.shade800,
                    onChanged: (value) {
                      setModalState(() => _fontSize = value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. Glow Effekt Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _color,
                    title: const Text(
                      "Neon Glow Effekt",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "Besserer Kontrast auf Wallpapern",
                      style: TextStyle(color: Colors.grey),
                    ),
                    value: _enableGlow,
                    onChanged: (val) {
                      setModalState(() => _enableGlow = val);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 20),

                  // 4. Schriftart
                  const Text(
                    "Schriftart",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.grey[900],
                        value: _currentFont,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        items: _fontOptions
                            .map(
                              (font) => DropdownMenuItem(
                                value: font,
                                child: Text(
                                  font.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => _currentFont = value);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _colorOption(Color color, Function setModalState) {
    bool isSelected = _color == color;

    return GestureDetector(
      onTap: () {
        setModalState(() => _color = color);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
          border: Border.all(color: Colors.white, width: isSelected ? 3 : 1),
        ),
      ),
    );
  }

  TextStyle _getStyle(double size, {bool isBold = false}) {
    List<Shadow> shadows = [];
    if (_enableGlow) {
      shadows = [
        Shadow(
          offset: const Offset(0, 0),
          blurRadius: 15.0,
          color: _color.withValues(alpha: 0.6),
        ),
        const Shadow(
          offset: Offset(2, 2),
          blurRadius: 5.0,
          color: Colors.black54,
        ),
      ];
    } else {
      shadows = [
        const Shadow(
          offset: Offset(1, 1),
          blurRadius: 2.0,
          color: Colors.black87,
        ),
      ];
    }

    return TextStyle(
      fontSize: size,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: _color,
      shadows: shadows,
      fontFamily: _currentFont == 'pixel'
          ? 'PixelFont'
          : _currentFont == 'serif'
          ? 'SerifFont'
          : _currentFont == 'mono'
          ? 'MonoFont'
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // Uhr mittig
      child: GestureDetector(
        onLongPress: _openStyleDialog, // Nur LongPress
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _timeString,
                style: _getStyle(_fontSize, isBold: true).copyWith(height: 0.9),
              ),

              const SizedBox(height: 10),

              Text(
                _dateString.toUpperCase(),
                style: _getStyle(_fontSize * 0.25).copyWith(
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),

              const SizedBox(height: 20),

              _buildBatteryIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryIndicator() {
    Color batteryColor = _batteryLevel > 20 ? _color : Colors.redAccent;
    IconData icon = Icons.battery_full;

    if (_batteryState == BatteryState.charging) {
      icon = Icons.battery_charging_full;
      batteryColor = Colors.greenAccent;
    } else {
      if (_batteryLevel <= 20) {
        icon = Icons.battery_alert;
      } else if (_batteryLevel <= 50) {
        icon = Icons.battery_4_bar;
      } else if (_batteryLevel <= 80) {
        icon = Icons.battery_6_bar;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: batteryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            "$_batteryLevel%",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
