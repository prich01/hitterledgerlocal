import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;           // Required for image processing
import 'dart:io';               // Required for saving the temporary file
import 'dart:typed_data';       // Required for handling the image bytes
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart'; // Required for the RepaintBoundary logic
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart'; // Required for temporary storage
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Launch the UI immediately (no white screen!)
  runApp(const HittersLedgerApp());

  // 2. Try to connect to the database quietly in the background
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("⚾ CLOUD STATUS: Firebase is connected and ready!");
  } catch (e) {
    print("❌ CLOUD STATUS: Connection failed, but the app is still running. Error: $e");
  }
}

class HittersLedgerApp extends StatelessWidget {
  const HittersLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "The Hitter's Ledger",
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF0F1113),
        // FIXED: Changed CardThemeData to CardTheme
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1D21),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 18,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1D21),
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
        ),
        // FIXED: Changed TabBarThemeData to TabBarTheme
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white38,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
    home: const SplashScreen(),
    );
  }
}

class StadiumLightingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final baseGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFF0F1113),
        const Color(0xFF14171A),
        const Color(0xFF0F1113),
      ],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = baseGradient);

    final Paint turfPaint = Paint()
      ..color = Colors.green.withOpacity(0.02)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 100; i++) {
      canvas.drawCircle(
        Offset(size.width * (i * 0.13 % 1), size.height * (i * 0.17 % 1)),
        2,
        turfPaint,
      );
    }

    final lightColor = const Color(0xFFD4AF37).withOpacity(0.08);
    
    canvas.drawCircle(
      Offset(size.width * 0.2, -50),
      size.height * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [lightColor, Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, -50), radius: size.height * 0.6)),
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, -50),
      size.height * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [lightColor, Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, -50), radius: size.height * 0.6)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// DATA MODELS
// =============================================================================
class CageRoutine {
  final String title;
  final String content;

  CageRoutine({required this.title, required this.content});

  Map<String, dynamic> toJson() => {'title': title, 'content': content};

  static CageRoutine fromJson(Map<String, dynamic> json) => 
      CageRoutine(title: json['title'] ?? '', content: json['content'] ?? '');
}

class Pitch {
  final Offset location; 
  final String type;
  final Color color;
  final bool isFoul;
  final bool isMiss; 

  Pitch({
    required this.location, 
    required this.type, 
    required this.color, 
    this.isFoul = false, 
    this.isMiss = false
  });
 
  // ... existing fields ...
  Map<String, dynamic> toJson() => {
    'dx': location.dx, 'dy': location.dy, 'type': type, 'color': color.value, 'isFoul': isFoul, 'isMiss': isMiss
  };
  static Pitch fromJson(Map<String, dynamic> json) => Pitch(
    location: Offset(json['dx'], json['dy']), type: json['type'], color: Color(json['color']), isFoul: json['isFoul'], isMiss: json['isMiss']
  );
}

class AtBatLog {
  final String pitcher;
  final String team;
  final String date;
  final String hand;
  final String velocity;
  final String result;
  final String swingThought;
  final String notes;
  final bool isQAB;
  final List<Pitch> pitches;
  final String gameLabel; // ADD THIS
  final int abNumber;     // ADD THIS
  final String season;

  AtBatLog({
    required this.pitcher,
    required this.team,
    required this.date,
    required this.hand,
    required this.velocity,
    required this.result,
    required this.swingThought,
    required this.notes,
    required this.isQAB,
    required this.pitches,
    required this.gameLabel, // ADD THIS
    required this.abNumber,   // ADD THIS
    required this.season,
  });

  Map<String, dynamic> toJson() => {
    'pitcher': pitcher,
    'team': team,
    'date': date,
    'hand': hand,
    'velocity': velocity,
    'result': result,
    'swingThought': swingThought,
    'notes': notes,
    'isQAB': isQAB,
    'pitches': pitches.map((p) => p.toJson()).toList(),
    'gameLabel': gameLabel, // ADD THIS
    'abNumber': abNumber,   // ADD THIS
    'season': season,
  };

  static AtBatLog fromJson(Map<String, dynamic> json) => AtBatLog(
    pitcher: json['pitcher'] ?? '',
    team: json['team'] ?? '',
    date: json['date'] ?? '',
    hand: json['hand'] ?? '',
    velocity: json['velocity'] ?? '',
    result: json['result'] ?? '',
    swingThought: json['swingThought'] ?? '',
    notes: json['notes'] ?? '',
    isQAB: json['isQAB'] ?? false,
    pitches: (json['pitches'] as List? ?? []).map((p) => Pitch.fromJson(p)).toList(),
    gameLabel: json['gameLabel'] ?? '', // ADD THIS
    abNumber: json['abNumber'] ?? 1,    // ADD THIS
    season: json['season'] ?? 'SPRING 2026',
  );
}

// =============================================================================
// SPLASH SCREEN
// =============================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // This timer tells the app to wait 3 seconds, then move to the Home screen
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We use a Stack to layer the logo ON TOP of the background
      body: Stack(
        children: [
          // 1. The Background Layer (Fills the entire screen)
          Positioned.fill(
            child: Image.asset(
              'assets/stadium_bg.png', 
              fit: BoxFit.cover, // This stretches/crops to ensure no black bars
            ),
          ),
          
          // 2. The Logo Layer (Stays centered and proportional)
          Center(
            child: Image.asset(
              'assets/hl_logo.png',
              width: 280, // Adjusted slightly larger for impact
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
// =============================================================================
// HOME SCREEN
// =============================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("THE HITTER'S LEDGER"),
      ),
      
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: StadiumLightingPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeroCard(
                  context,
                  "YOUR LEDGER",
                  "RECORD AT-BATS & SCOUT",
                  Icons.analytics_outlined,
                  const Color(0xFFD4AF37),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) =>  HitterLogScreen())),
                ),
                const SizedBox(height: 24),
         Expanded(
  child: GridView.count(
    physics: const ClampingScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
   children: [
      _buildMenuCard(context, "5 TRUTHS", Icons.bolt, Colors.blue, const SimpleTruthsScreen()),
      _buildMenuCard(context, "IMAGERY", Icons.remove_red_eye_outlined, Colors.purple, const MentalImageryScreen()),
      _buildMenuCard(context, "SWING THOUGHTS", Icons.psychology_outlined, Colors.green, const SwingThoughtsScreen()),
      _buildMenuCard(context, "CAGE ROUTINES", Icons.sports_baseball_outlined, Colors.red, const CageRoutinesScreen()),
    ],
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
  Widget _buildHeroCard(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(width: 24),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                Text(sub, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold)),
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color.withOpacity(0.8)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }



// =============================================================================
// HITTER LOG MODULE
// =============================================================================

// 1. AT-BAT LOG MODEL (Standing alone, outside other classes)

 

// 2. THE SCREEN WIDGET
class HitterLogScreen extends StatefulWidget {
  const HitterLogScreen({super.key});
  @override State<HitterLogScreen> createState() => _HitterLogScreenState();
}

// 3. THE SCREEN STATE (Where the logic lives)
class _HitterLogScreenState extends State<HitterLogScreen> {
  // YOUR VARIABLES START HERE
  final List<AtBatLog> _allLogs = [];
  // --- ADD THESE SEASON VARIABLES ---
  List<String> _seasons = ['SPRING 2026']; // Initial default season
  String _activeSeason = 'SPRING 2026';    // The currently selected season
  // ----------------------------------
  // ADD THIS: A map to hold the keys for each card
  final Map<String, GlobalKey> _atBatKeys = {};

  // ADD THIS: The logic to turn the card into an image
  Future<void> _captureAndShare(GlobalKey key, String pitcherName, String result) async {
    try {
      RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final String fileName = 'at_bat_${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File('${directory.path}/$fileName');
      await imageFile.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: "At-Bat vs $pitcherName ($result) - Shared from The Hitter's Ledger",
      );
    } catch (e) {
      debugPrint("Error capturing/sharing: $e");
    }
  }
  
  
  // YOUR FUNCTIONS (Save/Load)
  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_allLogs.map((log) => log.toJson()).toList());
    await prefs.setString('all_at_bats', encodedData);
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('all_at_bats');
    if (savedData != null) {
      final List decoded = jsonDecode(savedData);
      setState(() {
        _allLogs.clear();
        _allLogs.addAll(decoded.map((item) => AtBatLog.fromJson(item)).toList());
      });
    }
  }

  // ... the rest of your build code ...
  String _userName = "PLAYER"; // Default name
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _loadUserName();
    _loadSeasons(); // ADD THIS LINE
  }

  // LOAD NAME FROM MEMORY
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "";
    });
    
    // If no name is found, ask for it immediately
    if (_userName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNameDialog());
    }
  }

  // SAVE NAME TO MEMORY
  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() {
      _userName = name;
    });
  }
  // SAVE SEASONS TO MEMORY
  Future<void> _saveSeasons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_seasons', _seasons);
    await prefs.setString('active_season', _activeSeason);
  }

  // LOAD SEASONS FROM MEMORY
  Future<void> _loadSeasons() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _seasons = prefs.getStringList('user_seasons') ?? ['SPRING 2026'];
      _activeSeason = prefs.getString('active_season') ?? _seasons.first;
    });
  }

  // HELPER TO ADD A NEW SEASON
  Future<String?> _showNewSeasonInput() async {
    String? newName;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D21),
        title: const Text("NEW SEASON NAME", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14)),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: "e.g. FALL BALL 2026"),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) => newName = value.toUpperCase(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ADD", style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
    return newName;
  }
  void _showSeasonPicker(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1D21),
            title: const Text("SELECT SEASON", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._seasons.map((s) => ListTile(
                        title: Text(s, style: TextStyle(color: s == _activeSeason ? const Color(0xFFD4AF37) : Colors.white)),
                        trailing: s == _activeSeason ? const Icon(Icons.check, color: Color(0xFFD4AF37)) : null,
                        onTap: () {
                          setState(() => _activeSeason = s);
                          _saveSeasons();
                          Navigator.pop(context);
                        },
                      )),
                  const Divider(color: Colors.white24),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFFD4AF37)),
                    label: const Text("ADD NEW SEASON", style: TextStyle(color: Color(0xFFD4AF37))),
                    onPressed: () async {
                      String? newName = await _showNewSeasonInput();
                      if (newName != null && newName.isNotEmpty) {
                        setDialogState(() {
                          if (!_seasons.contains(newName)) _seasons.add(newName);
                          _activeSeason = newName;
                        });
                        setState(() {}); 
                        _saveSeasons();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  // POPUP DIALOG TO ASK FOR NAME
  void _showNameDialog() {
    showDialog(
      barrierDismissible: false, // User must enter a name
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D21),
        title: const Text("WELCOME, HITTER", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: "Enter Your Name"),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                _saveUserName(_nameController.text.toUpperCase());
                Navigator.pop(context);
              }
            },
            child: const Text("START", style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }
  void _confirmDelete(AtBatLog log) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D21),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("DELETE ENTRY?", 
            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete this at-bat against ${log.pitcher}?"),
          actions: [
            TextButton(
              child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
         onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
         onPressed: () {
                setState(() {
                  _allLogs.remove(log);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ENTRY DELETED")),
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedHandFilter = "All";
  String _selectedPitchFilter = "All";
  
  String _chaseHandFilter = "All";
  String _chasePitchFilter = "All"; 
  
  String _firstHandFilter = "All";
  String _firstPitchFilter = "All"; 
  
  bool _resultPitchOnly = true; 

  final Map<String, Color> _pData = {
    "Fastball": Colors.red, "Slider": Colors.blue, "Curveball": Colors.cyan, 
    "Changeup": Colors.green, "Cutter": Colors.orange, "Other": Colors.purple
  };

  String _calculateAVG(List<AtBatLog> logs) {
    if (logs.isEmpty) return ".000";
    final hits = logs.where((l) => ["1B", "2B", "3B", "HR", "Bunt Single"].contains(l.result)).length;
    final abs = logs.where((l) => !["BB", "HBP", "SAC Bunt", "SAC Fly", "Catcher's Interference"].contains(l.result)).length;
    return abs == 0 ? ".000" : (hits / abs).toStringAsFixed(3).replaceFirst("0", "");
  }

  String _calculateSLG(List<AtBatLog> logs) {
    if (logs.isEmpty) return ".000";
    final abs = logs.where((l) => !["BB", "HBP", "SAC Bunt", "SAC Fly", "Catcher's Interference"].contains(l.result)).length;
    if (abs == 0) return ".000";
    int singles = logs.where((l) => l.result == "1B" || l.result == "Bunt Single").length;
    int doubles = logs.where((l) => l.result == "2B").length;
    int triples = logs.where((l) => l.result == "3B").length;
    int hrs = logs.where((l) => l.result == "HR").length;
    double tb = (singles * 1.0) + (doubles * 2.0) + (triples * 3.0) + (hrs * 4.0);
    return (tb / abs).toStringAsFixed(3).replaceFirst("0", "");
  }

  void _shareAtBat(AtBatLog log) {
    final String message = "⚾ AT-BAT RESULT: ${log.result}\n"
        "📅 DATE: ${log.date}\n"
        "🔥 PITCHER: ${log.pitcher}\n"
        "💭 THOUGHT: ${log.swingThought}\n\n"
        "Shared from The Hitter's Ledger";

    Share.share(
      message,
      subject: 'My At-Bat Performance',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 10, 10),
    );
  }

  String _calculateOBP(List<AtBatLog> logs) {
    if (logs.isEmpty) return ".000";
    final onBase = logs.where((l) => ["1B", "2B", "3B", "HR", "Bunt Single", "BB", "HBP"].contains(l.result)).length;
    return (onBase / logs.length).toStringAsFixed(3).replaceFirst("0", "");
  }

  double _calculateChaseRate(List<AtBatLog> logs, {String pitchType = "All", String hand = "All"}) {
    int oZonePitches = 0;
    int oZoneSwings = 0;
    
    List<AtBatLog> filteredLogs = logs.where((l) {
      if (hand == "All") return true;
      return l.hand == (hand == "RHP" ? "R" : "L");
    }).toList();

    for (var log in filteredLogs) {
      for (int i = 0; i < log.pitches.length; i++) {
        var p = log.pitches[i];
        if (pitchType != "All" && p.type != pitchType) continue;

        bool isOutside = (p.location.dx < 0.25 || p.location.dx > 0.75 || p.location.dy < 0.28 || p.location.dy > 0.77);
        if (isOutside) {
          oZonePitches++;
          bool isContact = (i == log.pitches.length - 1) && !["BB", "HBP", "K"].contains(log.result);
          if (p.isFoul || p.isMiss || isContact) oZoneSwings++;
        }
      }
    }
    return oZonePitches == 0 ? 0.0 : (oZoneSwings / oZonePitches) * 100;
  }

  double _calculateFirstPitchSwing(List<AtBatLog> logs, {String pitchType = "All", String hand = "All"}) {
    int totalFirstPitches = 0;
    int firstPitchSwings = 0;

    List<AtBatLog> filteredLogs = logs.where((l) {
      if (hand == "All") return true;
      return l.hand == (hand == "RHP" ? "R" : "L");
    }).toList();

    for (var log in filteredLogs) {
      if (log.pitches.isNotEmpty) {
        var p = log.pitches[0];
        if (pitchType != "All" && p.type != pitchType) continue;
        
        totalFirstPitches++;
        bool isContact = (log.pitches.length == 1) && !["BB", "HBP", "K"].contains(log.result);
        if (p.isFoul || p.isMiss || isContact) firstPitchSwings++;
      }
    }
    return totalFirstPitches == 0 ? 0.0 : (firstPitchSwings / totalFirstPitches) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _userName == "PLAYER" ? "YOUR LEDGER" : "${_userName}'S LEDGER",
            style: const TextStyle(fontSize: 14), 
          ),
          // --- PASTE THIS SECTION ---
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                backgroundColor: const Color(0xFF1A1D21),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
                label: Text(
                  _activeSeason,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37), 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold
                  ),
                ),
           onPressed: () => _showSeasonPicker(context),
              ),
            ),
          ],
          // ---------------------------
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFFD4AF37),
            tabs: [
              Tab(icon: Icon(Icons.history), text: "History"),
              Tab(icon: Icon(Icons.bar_chart), text: "Season"),
              Tab(icon: Icon(Icons.whatshot), text: "Heat Map"),
              Tab(icon: Icon(Icons.shield_outlined), text: "QAB%"),
              Tab(icon: Icon(Icons.track_changes), text: "Chase"),
              Tab(icon: Icon(Icons.flash_on), text: "1st Pitch"),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildHistoryTab(),
            _buildSeasonStatsTab(),
            _buildHeatMapTab(),
            _buildStatPage("QAB %", (logs) => logs.isEmpty ? 0 : (logs.where((l) => l.isQAB).length / logs.length) * 100, Colors.greenAccent, "qab"),
            _buildStatPage("CHASE RATE", (logs) => _calculateChaseRate(logs, pitchType: _chasePitchFilter, hand: _chaseHandFilter), Colors.redAccent, "chase"),
            _buildStatPage("1ST PITCH SWING", (logs) => _calculateFirstPitchSwing(logs, pitchType: _firstPitchFilter, hand: _firstHandFilter), Colors.blueAccent, "first"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFD4AF37),
     onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EntryForm(pData: _pData)));
            if (result != null && result is AtBatLog) setState(() => _allLogs.insert(0, result));
            _saveLogs();
          },
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }

Widget _buildHistoryTab() {
    final query = _searchController.text.trim().toLowerCase();

    // 1. FIRST: Filter all logs by the Active Season selected in the top bar
    List<AtBatLog> seasonalResults = _allLogs.where((l) => l.season == _activeSeason).toList();

    // 2. SECOND: Filter those seasonal results by the search query
    List<AtBatLog> results = seasonalResults.where((l) {
      if (query.isEmpty) return true;
      final searchLower = query.toLowerCase();
      return l.pitcher.toLowerCase().contains(searchLower) ||
             l.team.toLowerCase().contains(searchLower) ||
             l.date.toLowerCase().contains(searchLower);
    }).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() {}),
          decoration: const InputDecoration(
            hintText: "SEARCH PITCHER NAME...",
            prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFFD4AF37)),
          ),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: _pData.entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              CircleAvatar(radius: 4, backgroundColor: e.value),
              const SizedBox(width: 6),
              Text(e.key.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38)),
            ]),
          )).toList(),
        ),
      ),
      const Divider(color: Colors.white10, height: 1),
      Expanded(
        child: seasonalResults.isEmpty 
          ? Center(child: Text("NO RECORDS FOUND FOR $_activeSeason", style: const TextStyle(color: Colors.white24, letterSpacing: 1.5, fontSize: 12)))
          : ListView(
              physics: const ClampingScrollPhysics(),
              children: [
              if (query.isNotEmpty && results.isNotEmpty) _buildScoutingReport(query, results),
              ...results.map((log) => _buildHistoryCard(log)).toList(),
              const SizedBox(height: 100),
            ]),
      ),
    ]);
  }

  Widget _buildScoutingReport(String name, List<AtBatLog> logs) {
    int s = logs.where((l) => l.result == "1B" || l.result == "Bunt Single").length;
    int d = logs.where((l) => l.result == "2B").length;
    int t = logs.where((l) => l.result == "3B").length;
    int hr = logs.where((l) => l.result == "HR").length;
    int bb = logs.where((l) => l.result == "BB").length;
    int hbp = logs.where((l) => l.result == "HBP").length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 24),
            Text("SCOUTING: ${name.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), fontSize: 14)),
            IconButton(
              icon: const Icon(Icons.ios_share, size: 18, color: Color(0xFFD4AF37)),
              onPressed: () {
                String reportText = "SCOUTING: ${name.toUpperCase()}\nAVG: ${_calculateAVG(logs)} | SLG: ${_calculateSLG(logs)}";
                Clipboard.setData(ClipboardData(text: reportText));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SCOUTING REPORT COPIED")));
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _miniStat("AVG", _calculateAVG(logs)),
          _miniStat("SLG", _calculateSLG(logs)),
          _miniStat("QAB%", logs.isEmpty ? "0%" : "${(logs.where((l)=>l.isQAB).length/logs.length*100).toStringAsFixed(0)}%"),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _tinyStat("1B", "$s"),
          _tinyStat("2B", "$d"),
          _tinyStat("3B", "$t"),
          _tinyStat("HR", "$hr"),
          _tinyStat("BB", "$bb"),
          _tinyStat("HBP", "$hbp"),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(color: Colors.white10)),
        _buildZoneMap(logs),
      ]),
    );
  }

  Widget _miniStat(String l, String v) => Column(children: [Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold))]);
  
  Widget _tinyStat(String l, String v) => Column(children: [
    Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
    Text(l, style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold))
  ]);

Widget _buildHistoryCard(AtBatLog log) {
  // 1. Generate the unique key for this specific log entry
  final String logId = "${log.pitcher}_${log.date}"; 
  _atBatKeys[logId] ??= GlobalKey();
  final GlobalKey cardKey = _atBatKeys[logId]!;

  // 2. Updated Legend helper with your specific colors and labels
  Widget buildInlineLegend() {
    final Map<String, Color> pitchColors = {
      "Fastball": Colors.red, 
      "Slider": Colors.blue, 
      "Curveball": Colors.cyan, 
      "Changeup": Colors.green, 
      "Cutter": Colors.orange, 
      "Other": Colors.purple
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pitchColors.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                entry.key.toUpperCase(), // Makes it look clean like the rest of your UI
                style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 3. Return the RepaintBoundary wrapping the Card
  return RepaintBoundary(
    key: cardKey,
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        iconColor: const Color(0xFFD4AF37),
        title: Text(
          log.pitcher.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          "${log.result} • ${log.date}",
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.blueAccent, size: 20),
              onPressed: () => _captureAndShare(cardKey, log.pitcher, log.result),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDelete(log),
            ),
            const Icon(Icons.expand_more, color: Colors.white38),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TEAM: ${log.team} | ${log.hand}HP | VELO: ${log.velocity}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const Divider(height: 24, color: Colors.white10),
                if (log.swingThought.isNotEmpty) ...[
                  Text(
                    "THOUGHT: ${log.swingThought}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        _buildMiniMap(log.pitches),
                        const SizedBox(height: 12),
                        buildInlineLegend(),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        "NOTES: ${log.notes}",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    ),
  );
}
  Widget _buildSeasonStatsTab() {
  // 1. Create a filtered list for the active season
  final seasonalLogs = _allLogs.where((l) => l.season == _activeSeason).toList();

  return ListView(
    physics: const ClampingScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        // 2. Pass 'seasonalLogs' instead of '_allLogs' to the stat calculators
        _largeStatCard("AVG", _calculateAVG(seasonalLogs), const Color(0xFFD4AF37)),
        _largeStatCard("SLG", _calculateSLG(seasonalLogs), Colors.blueAccent),
        _largeStatCard("OBP", _calculateOBP(seasonalLogs), Colors.greenAccent),
      ]),
      const SizedBox(height: 32),
      // 3. Update the rows to count from 'seasonalLogs'
      _buildStatRow("TOTAL HITS", "${seasonalLogs.where((l) => ["1B", "2B", "3B", "HR", "Bunt Single"].contains(l.result)).length}"),
      _buildStatRow("WALKS (BB/HBP)", "${seasonalLogs.where((l) => ["BB", "HBP"].contains(l.result)).length}"),
      _buildStatRow("STRIKEOUTS (K)", "${seasonalLogs.where((l) => l.result == "K").length}"),
      _buildStatRow("QABS RECORDED", "${seasonalLogs.where((l)=>l.isQAB).length}"),
      _buildStatRow("OVERALL CHASE", "${_calculateChaseRate(seasonalLogs).toStringAsFixed(1)}%"),
      _buildStatRow("OVERALL 1ST PITCH", "${_calculateFirstPitchSwing(seasonalLogs).toStringAsFixed(1)}%"),
    ],
  );
}

  Widget _largeStatCard(String label, String val, Color col) => Container(
    width: 100, padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(color: const Color(0xFF1A1D21), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Column(children: [Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: col)), Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold))]));

  Widget _buildStatRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.bold)), Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))]));

  Widget _buildHeatMapTab() {
    List<AtBatLog> filtered = _allLogs.where((l) => l.season == _activeSeason && (_selectedHandFilter == "All" || l.hand == (_selectedHandFilter == "RHP" ? "R" : "L"))).toList();
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(children: [
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _filterDropdown("HAND", _selectedHandFilter, ["All", "RHP", "LHP"], (v) => setState(() => _selectedHandFilter = v!)),
          _filterDropdown("PITCH", _selectedPitchFilter, ["All", "Fastball", "Slider", "Curveball", "Changeup", "Cutter"], (v) => setState(() => _selectedPitchFilter = v!)),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("RESULT PITCH ONLY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38)),
              Switch(
                value: _resultPitchOnly,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (v) => setState(() => _resultPitchOnly = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildZoneMap(filtered, pitchTypeFilter: _selectedPitchFilter, resultOnly: _resultPitchOnly),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _filterDropdown(String l, String val, List<String> items, Function(String?) onC) => DropdownButton<String>(
    value: val, underline: const SizedBox(), dropdownColor: const Color(0xFF1A1D21),
    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12),
    items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: onC);

  // UPDATED UI: Includes Pitcher Hand Dropdown AND QAB Breakdown logic
  Widget _buildStatPage(String title, double Function(List<AtBatLog>) calc, Color col, String mode) {
    // 1. Create the filtered list for the active season
    final seasonalLogs = _allLogs.where((l) => l.season == _activeSeason).toList();
    
    // 2. Pass the seasonal logs to the calculator instead of _allLogs
    double val = calc(seasonalLogs);
    String activePitchFilter = mode == "chase" ? _chasePitchFilter : mode == "first" ? _firstPitchFilter : "All";
    String activeHandFilter = mode == "chase" ? _chaseHandFilter : mode == "first" ? _firstHandFilter : "All";

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        if (mode == "chase" || mode == "first") 
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _filterDropdown("HAND", activeHandFilter, ["All", "RHP", "LHP"], (v) {
                  setState(() {
                    if (mode == "chase") _chaseHandFilter = v!;
                    if (mode == "first") _firstHandFilter = v!;
                  });
                }),
                _filterDropdown("PITCH", activePitchFilter, ["All", ..._pData.keys], (v) {
                  setState(() {
                    if (mode == "chase") _chasePitchFilter = v!;
                    if (mode == "first") _firstPitchFilter = v!;
                  });
                }),
              ],
            ),
          ),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white54)),
        Text("${val.toStringAsFixed(1)}%", style: TextStyle(fontSize: 64, color: col, fontWeight: FontWeight.w900)),
        const SizedBox(height: 30),
        
        // ** NEW: QAB BREAKDOWN LOGIC INSERTED HERE **
        if (mode == "qab") ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1A1D21), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Text("QAB BREAKDOWN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24)),
              const SizedBox(height: 20),
              _buildSimpleBar("VS RHP", 
                () {
                  final rLogs = seasonalLogs.where((l) => l.hand == "R").toList();
                  if (rLogs.isEmpty) return 0.0;
                  return (rLogs.where((l) => l.isQAB).length / rLogs.length) * 100;
                }(), 
                col
              ),
              const SizedBox(height: 20),
              _buildSimpleBar("VS LHP", 
                () {
                  final lLogs = seasonalLogs.where((l) => l.hand == "L").toList();
                  if (lLogs.isEmpty) return 0.0;
                  return (lLogs.where((l) => l.isQAB).length / lLogs.length) * 100;
                }(), 
                col
              ),
            ]),
          ),
          const SizedBox(height: 30),
        ],
        // ** END NEW QAB CODE **

        if (mode != "qab") _buildZoneMap(seasonalLogs, mode: mode, pitchTypeFilter: activePitchFilter, handFilter: activeHandFilter),
        const SizedBox(height: 100),
      ]),
    );
  }

  // ** ADDED HELPER METHOD FOR BARS **
  Widget _buildSimpleBar(String label, double val, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text("${val.toStringAsFixed(1)}%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col)),
          ]
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: val / 100, 
          backgroundColor: Colors.white10, 
          color: col, 
          minHeight: 6
        ),
      ]
    );
  }

  Widget _buildZoneMap(List<AtBatLog> logs, {String pitchTypeFilter = "All", String mode = "all", bool resultOnly = false, String handFilter = "All"}) {
    return Container(width: 220, height: 260, decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)), child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: SeasonHeatPainter(logs: logs, pitchTypeFilter: pitchTypeFilter, specialMode: mode, resultOnly: resultOnly, handFilter: handFilter))),
      Center(child: _buildStrikeGrid(110, 140)),
    ]));
  }

  Widget _buildStrikeGrid(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(border: Border.all(color: Colors.white24)), child: Stack(children: [Row(children: [const Spacer(), VerticalDivider(color: Colors.white10, width: 1), const Spacer(), VerticalDivider(color: Colors.white10, width: 1), const Spacer()]), Column(children: [const Spacer(), Divider(color: Colors.white10, height: 1), const Spacer(), Divider(color: Colors.white10, height: 1), const Spacer()])]));

  Widget _buildMiniMap(List<Pitch> pitches) {
    return Container(width: 120, height: 140, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)), child: Stack(children: [
      Center(child: _buildStrikeGrid(60, 75)), 
      ...pitches.asMap().entries.map((e) => Positioned(
        left: (e.value.location.dx * 120) - 7, 
        top: (e.value.location.dy * 140) - 7, 
        child: CircleAvatar(
          radius: 7, 
          backgroundColor: e.value.color, 
          child: Text(
            "${e.key + 1}${e.value.isFoul ? 'F' : e.value.isMiss ? 'M' : ''}", 
            style: const TextStyle(fontSize: 6, color: Colors.black, fontWeight: FontWeight.bold)
          )
        )
      )),
    ]));
  }
}

class SeasonHeatPainter extends CustomPainter {
  final List<AtBatLog> logs;
  final String pitchTypeFilter;
  final String specialMode;
  final bool resultOnly;
  final String handFilter; 

  SeasonHeatPainter({required this.logs, required this.pitchTypeFilter, required this.specialMode, this.resultOnly = false, this.handFilter = "All"});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    for (var log in logs) {
      if (handFilter != "All" && log.hand != (handFilter == "RHP" ? "R" : "L")) continue;

      bool isHit = ["1B", "2B", "3B", "HR", "Bunt Single"].contains(log.result);
      final paint = ui.Paint()..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 15)..color = isHit ? Colors.red.withOpacity(0.5) : Colors.blue.withOpacity(0.3);
      
      List<Pitch> pitchesToDraw = (resultOnly && log.pitches.isNotEmpty) ? [log.pitches.last] : log.pitches;

      for (int i = 0; i < pitchesToDraw.length; i++) {
        var p = pitchesToDraw[i];
        bool draw = (pitchTypeFilter == "All" || p.type == pitchTypeFilter);
        
        if (specialMode == "chase") {
          draw = draw && (p.location.dx < 0.25 || p.location.dx > 0.75 || p.location.dy < 0.28 || p.location.dy > 0.77);
          bool isContact = (i == log.pitches.length - 1) && !["BB", "HBP", "K"].contains(log.result);
          draw = draw && (p.isFoul || p.isMiss || isContact);
        }
        
        if (specialMode == "first") {
           draw = draw && (i == 0);
           bool isContact = (log.pitches.length == 1) && !["BB", "HBP", "K"].contains(log.result);
           draw = draw && (p.isFoul || p.isMiss || isContact);
        }

        if (draw) canvas.drawCircle(Offset(p.location.dx * size.width, p.location.dy * size.height), 18, paint);
      }
    }
  }
  @override bool shouldRepaint(CustomPainter old) => true;
}
// =============================================================================
// ENTRY FORM
// =============================================================================

class EntryForm extends StatefulWidget {
  final Map<String, Color> pData;
  const EntryForm({super.key, required this.pData});
  @override State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final _pitcher = TextEditingController(), _team = TextEditingController(), _velo = TextEditingController(), _notes = TextEditingController(), _swingThought = TextEditingController(), _date = TextEditingController(text: DateFormat('MM/dd/yy').format(DateTime.now()));
  final List<Pitch> _sequence = [];
  String _res = "1B", _hand = "R";
  int _selectedAB = 1;
  bool _qab = false;
  final List<String> _outcomes = ["1B", "2B", "3B", "HR", "Bunt Single", "SAC Bunt", "SAC Fly", "BB", "HBP", "K", "Flyout", "Groundout", "Line Drive Out", "Catcher's Interference"];

  void _recordPitch(Offset loc) {
    bool isFoul = false;
    bool isMiss = false;

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(color: Color(0xFF1A1D21), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: StatefulBuilder(builder: (ctx, setM) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
          
          SwitchListTile(
            title: const Text("FOUL BALL?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 
            value: isFoul, 
            activeColor: const Color(0xFFD4AF37), 
            onChanged: (v) => setM(() { 
              isFoul = v; 
              if (v) isMiss = false; 
            })
          ),
          
          SwitchListTile(
            title: const Text("SWING & MISS?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 
            value: isMiss, 
            activeColor: Colors.redAccent, 
            onChanged: (v) => setM(() { 
              isMiss = v; 
              if (v) isFoul = false; 
            })
          ),

          const Divider(color: Colors.white10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2, childAspectRatio: 3,
              children: widget.pData.keys.map((t) => ListTile(
                leading: CircleAvatar(backgroundColor: widget.pData[t], radius: 8), 
                title: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), 
                onTap: () {
                  setState(() => _sequence.add(Pitch(
                    location: Offset(loc.dx / 300, loc.dy / 330), 
                    type: t, 
                    color: widget.pData[t]!, 
                    isFoul: isFoul,
                    isMiss: isMiss
                  )));
                  Navigator.pop(context);
                }
              )).toList(),
            ),
          ),
        ])),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NEW LEDGER ENTRY")),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24), 
        child: Column(children: [
        Row(children: [
          Expanded(child: TextField(controller: _date, decoration: const InputDecoration(labelText: "DATE"))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _velo, decoration: const InputDecoration(labelText: "VELO"), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _pitcher, decoration: const InputDecoration(labelText: "PITCHER NAME"))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _team, decoration: const InputDecoration(labelText: "TEAM"))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _hand, decoration: const InputDecoration(labelText: "HAND"), items: ["R", "L"].map((h) => DropdownMenuItem(value: h, child: Text("${h}HP"))).toList(), onChanged: (v) => setState(() => _hand = v!))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<int>(value: _selectedAB, decoration: const InputDecoration(labelText: "AB #"), items: [1,2,3,4,5,6,7,8].map((n) => DropdownMenuItem(value: n, child: Text("AB $n"))).toList(), onChanged: (v) => setState(() => _selectedAB = v!))),
        ]),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 300, height: 330, 
            decoration: BoxDecoration(
              color: Colors.black, 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.white10)
            ), 
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, 
              onTapDown: (details) {
                _recordPitch(details.localPosition);
              },
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 150, 
                      height: 165, 
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5))
                      )
                    )
                  ),
                  ..._sequence.asMap().entries.map((e) => Positioned(
                    left: (e.value.location.dx * 300) - 12, 
                    top: (e.value.location.dy * 330) - 12, 
                    child: CircleAvatar(
                      backgroundColor: e.value.color, 
                      radius: 12, 
                      child: Text(
                        "${e.key + 1}${e.value.isFoul ? 'F' : e.value.isMiss ? 'M' : ''}", 
                        style: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold)
                      )
                    )
                  )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(onPressed: () => setState(() => _sequence.isNotEmpty ? _sequence.removeLast() : null), icon: const Icon(Icons.undo, color: Colors.redAccent, size: 18), label: const Text("CLEAR LAST PITCH", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _res, decoration: const InputDecoration(labelText: "RESULT"), items: _outcomes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(() => _res = v!)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF1A1D21), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
          child: SwitchListTile(title: const Text("QUALITY AT-BAT", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), value: _qab, activeColor: const Color(0xFFD4AF37), onChanged: (v) => setState(() => _qab = v)),
        ),
        const SizedBox(height: 12),
        TextField(controller: _swingThought, decoration: const InputDecoration(labelText: "SWING THOUGHT")),
        const SizedBox(height: 12),
        TextField(controller: _notes, decoration: const InputDecoration(labelText: "NOTES")),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context, AtBatLog(pitcher: _pitcher.text, team: _team.text, hand: _hand, velocity: _velo.text, result: _res, pitches: List.from(_sequence), notes: _notes.text, date: _date.text, gameLabel: "", abNumber: _selectedAB, isQAB: _qab, swingThought: _swingThought.text, season: "")), child: const Text("SAVE TO LEDGER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5)))),
        const SizedBox(height: 40),
      ])),
    );
  }
}

// =============================================================================
// CONTENT MODULES (FULL VERBATIM SCRIPTS)
// =============================================================================

class SimpleTruthsScreen extends StatelessWidget {
  const SimpleTruthsScreen({super.key});
  final List<Map<String, String>> truths = const [
    {"title": "1. NOTHING REPLACES HARD WORK", "desc": "Confidence and consistency both come from preparation."},
    {"title": "2. THIS APP DOESN'T REPLACE MECHANICS", "desc": "Good hitters have good swings. Continue to work on your swing."},
    {"title": "3. APPROACH MATTERS", "desc": "Use this app to build your mental approach."},
    {"title": "4. DEFINE SUCCESS", "desc": "Success is about more than base hits. Hit the baseball hard."},
    {"title": "5. HAVE A GROWTH MINDSET", "desc": "Use failure as a means to grow and get better."},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("5 SIMPLE TRUTHS")),
      body: ListView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        itemCount: truths.length,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: const Color(0xFF1A1D21), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: ExpansionTile(
            title: Text(truths[index]['title']!, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), fontSize: 13)),
            children: [Padding(padding: const EdgeInsets.all(20), child: Text(truths[index]['desc']!, style: const TextStyle(color: Colors.white54, height: 1.5)))],
          ),
        ),
      ),
    );
  }
}

class MentalImageryScreen extends StatelessWidget {
  const MentalImageryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MENTAL IMAGERY")),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _buildImageryTile(context, "THE RAKE METHOD", "RELAX, ACKNOWLEDGE, KNOW, EXPERIENCE", Icons.air, Colors.blueAccent, const RakeMethodScreen()),
          _buildImageryTile(context, "PITCHER'S  SCRIPT", "VISUALIZING SUCCESS AT THE PLATE", Icons.menu_book, Colors.purpleAccent, const PitchersDuelScreen()),
          _buildImageryTile(context, "IDENTIFY YOUR ROUTINE", "BUILD YOUR RESET BUTTON", Icons.edit_calendar, Colors.orangeAccent, const IdentifyRoutineScreen()),
        ],
      ),
    );
  }
  Widget _buildImageryTile(BuildContext context, String title, String sub, IconData icon, Color color, Widget destination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: const Color(0xFF1A1D21), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      ),
    );
  }
}

class PitchersDuelScreen extends StatefulWidget {
  const PitchersDuelScreen({super.key});

  @override
  State<PitchersDuelScreen> createState() => _PitchersDuelScreenState();
}

class _PitchersDuelScreenState extends State<PitchersDuelScreen> {
  // 1. Setup the audio player and the play/stop toggle variable
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    // Resets button if the audio finishes on its own
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() => _isAudioPlaying = false);
    });
  }

  @override
  void dispose() {
    // 2. IMPORTANT: Stop the music if the user leaves the screen
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PITCHER'S DUEL")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // --- AUDIO CONTROL BUTTON ---
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_isAudioPlaying) {
                    await _audioPlayer.stop();
                    setState(() => _isAudioPlaying = false);
                  } else {
  // Use AssetSource for files inside your project
  // DO NOT include the word "assets/" in this string
  await _audioPlayer.play(AssetSource('pitchers_duel.mp3'));
  setState(() => _isAudioPlaying = true);
}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAudioPlaying ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF1A1D21),
                  side: BorderSide(color: _isAudioPlaying ? Colors.redAccent : const Color(0xFFD4AF37), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: Icon(
                  _isAudioPlaying ? Icons.stop_circle : Icons.play_circle_fill, 
                  color: _isAudioPlaying ? Colors.redAccent : const Color(0xFFD4AF37)
                ),
                label: Text(
                  _isAudioPlaying ? "STOP MEDITATION" : "PLAY MEDITATION SCRIPT", 
                  style: TextStyle(color: _isAudioPlaying ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 32),
            // --- SCRIPT TEXT ---
            const Text(
              "It’s time to relax. Time to let all the worry of today drift away. You are seated comfortably, and are about to consciously relax all of your muscles, one by one. Start with your hands. Let your fingers go limp… now your palms… now your wrists. Your forearms are completely relaxed now, and your elbows… your shoulders… and your back.\n\n"
              "Relax the muscles in your face. Your eyelids droop shut… the tension goes out of your neck. Your hips are loose and your thighs… your knees… your calves. Now your feet are going limp, every toe is relaxing. You are completely relaxed from head to toe. Breathe slowly and deeply from your diaphragm ten times, counting to five on each inhale, and five on each exhale.\n\n"
              "In your mind, open your eyes. Ahead of you, there is a door, centered in the wall about ten steps away from you. You are going to walk towards that door, and with each step the worries and anxieties you are dealing with today will drift further and further away until all you see is the door.\n\n"
              "Take one slow step toward the door. One. Take another step. Two. Another. Three. As you near the door, it begins to glow softly. Four. It is a warm welcoming light. Five. The door is beginning to swing open. Six. Through the door is light. Seven. Through the door is warmth. Eight. Through the door is safety. Nine. You are about to step through the door. Ten.\n\n"
              "You are standing, looking through the door at a baseball field. Step through the door, and shut it behind you. The sun is warm… The field is perfect… you can smell the fresh cut grass. Walk slowly to the field enjoying the gentle breeze and thinking how great it will be to play a game today and to be so relaxed and carefree.\n\n"
              "See yourself at the plate. Feel your feet as you dig in the batters box and feel yourself grip the bat. Look up to see the pitcher on the mound getting ready to deliver a pitch. See the pitch travel to your perfect location. Feel the ball hit the sweet spot of the barrel as you drive the baseball and know that this pitcher cannot beat you. Feel the confidence you have knowing that you are in control of the situation and take in the feeling of playing the game with the same approach that you had when you were 8 years old. NO WORRIES… NO FEAR… JUST FUN\n\n"
              "It’s been a great game today. Now you see a door about ten steps away, coming into shape.\n\n"
              "Ten. When you walk through the door you will be energized\n"
              "Nine. When you walk through the door, you will be well rested\n"
              "Eight. When you walk through the door, you will feel ready for today\n"
              "Seven. On the other side of that door is the world you left.\n"
              "Six. However, it has changed in your absence.\n"
              "Five. It is a calmer version of the world\n"
              "Four. There is nothing in the world that you cannot handle\n"
              "Three. You will have a great day today\n"
              "Two. Are you ready?\n"
              "One. Step through the door and open your eyes",
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}

class RakeMethodScreen extends StatefulWidget {
  const RakeMethodScreen({super.key});

  @override
  State<RakeMethodScreen> createState() => _RakeMethodScreenState();
}

class _RakeMethodScreenState extends State<RakeMethodScreen> {
  // Logic Variables
  int _seconds = 6;
  String _phase = "INHALE";
  bool _isActive = false;
  Timer? _timer;
  
  // Audio Variables
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    // This resets the button if the audio finishes on its own
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() => _isAudioPlaying = false);
    });
  }

  void _toggleBreathing() {
    if (_isActive) {
      _timer?.cancel();
      setState(() {
        _isActive = false;
        _phase = "READY?";
        _seconds = 6;
      });
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      _isActive = true;
      _phase = "INHALE";
      _seconds = 6;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 1) {
          _seconds--;
        } else {
          if (_phase == "INHALE") {
            _phase = "HOLD";
            _seconds = 2;
          } else if (_phase == "HOLD") {
            _phase = "EXHALE";
            _seconds = 8;
          } else {
            _phase = "INHALE";
            _seconds = 6;
          }
        }
      });
    });
  }

  @override
void dispose() {
  _audioPlayer.dispose(); // Cleans up the audio player
  // If you have a TabController or AnimationController, dispose them here too!
  super.dispose();        // Always keep this as the very last line
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RAKE METHOD")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TIMER BOX ---
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    _phase,
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.w900, 
                      color: _phase == "INHALE" ? Colors.blueAccent : (_phase == "HOLD" ? Colors.orangeAccent : Colors.greenAccent),
                      letterSpacing: 4
                    ),
                  ),
                  Text("$_seconds", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _toggleBreathing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isActive ? Colors.redAccent : const Color(0xFFD4AF37),
                      minimumSize: const Size(160, 40),
                    ),
                    child: Text(_isActive ? "STOP" : "START BREATH", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

        // --- RAKE TITLE AND AUDIO TOGGLE BUTTON ---
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center, // Vertically aligns button with "R-A-K-E"
      children: [
        const Text(
          "R-A-K-E", 
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.w900, 
            color: Color(0xFFD4AF37)
          )
        ),
        ElevatedButton.icon(
          onPressed: () async {
            if (_isAudioPlaying) {
              await _audioPlayer.stop();
              setState(() => _isAudioPlaying = false);
            } else {
              await _audioPlayer.play(AssetSource('rake_meditation.mp3'));
              setState(() => _isAudioPlaying = true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isAudioPlaying ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF1A1D21),
            side: BorderSide(color: _isAudioPlaying ? Colors.redAccent : const Color(0xFFD4AF37), width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(
            _isAudioPlaying ? Icons.stop_circle : Icons.play_circle_fill, 
            color: _isAudioPlaying ? Colors.redAccent : const Color(0xFFD4AF37), 
            size: 18
          ),
          label: Text(
            _isAudioPlaying ? "STOP AUDIO" : "RAKE AUDIO", 
            style: TextStyle(
              color: _isAudioPlaying ? Colors.redAccent : Colors.white, 
              fontSize: 10, 
              fontWeight: FontWeight.bold
            )
          ),
        ),
      ],
    ),
    const SizedBox(height: 4), // Small gap between title and subtitle
    const Text(
      "METHOD OF MENTAL IMAGERY", 
      style: TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.bold, 
        color: Colors.white38
      )
    ),
  ],
),

            const SizedBox(height: 32),
            _buildRakeStep("RELAX", "6-2-8 BREATHING", "Inhale 6 seconds, Hold 2 seconds, Exhale 8 seconds.", Icons.air_outlined, Colors.blueAccent),
            _buildRakeStep("ACKNOWLEDGE", "WHO YOU ARE", "Repeat statements of affirmation.", Icons.person_outline, Colors.purpleAccent),
            _buildRakeStep("KNOW", "YOUR PAST SUCCESS", "Replay previous highlights in your mind.", Icons.history, Colors.orangeAccent),
            _buildRakeStep("EXPERIENCE", "YOUR FUTURE SUCCESS", "Visualize specific moments of success.", Icons.visibility_outlined, Colors.greenAccent),
            
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
              ),
              child: Column(
                children:  [
                  Text("PRACTICE DAILY", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 1)),
                  SizedBox(height: 8),
                  Text(
                    "You can’t do anything that you can’t picture yourself doing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRakeStep(String title, String subtitle, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.white54, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
  Widget _buildRakeStep(String title, String subtitle, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.white54, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }


class IdentifyRoutineScreen extends StatelessWidget {
  const IdentifyRoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("IDENTIFY ROUTINE")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("IDENTIFY YOUR HITTING ROUTINE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37))),
            const SizedBox(height: 20),
            const Text(
              "The keys to success often lie in structure, consistency, and mental focus. The natural outcome of these is improved confidence. When you believe you are good then you certainly have a chance to be good! That is why a routine is so important. A routine acts as a “reset” button that regardless of circumstance allows you to lock in on the task at hand. Below are some common questions to ask to help determine our in game hitting routine.",
              style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildQuestionCard("Question #1: When does my at bat start?"),
            _buildQuestionCard("Question #2: What do you do when you are in the hole, and on deck?"),
            _buildQuestionCard("Question #3: What do you do when you are in the batter’s box at the plate?"),
            _buildQuestionCard("Question #4: Do you have a “release” for when things go bad? A release can be a verbal or physical cue that can help get you back on track after a bad call or a bad swing."),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white, height: 1.4),
      ),
    );
  }
}

class SwingThoughtsScreen extends StatelessWidget {
  const SwingThoughtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> thoughts = [
      "Breathe", "Be Aggressive", "Be on Time", 
      "Stay Short", "Attack", "Believe"
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("SWING THOUGHTS")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MINDSET & VERBAL CUES", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37))),
            const SizedBox(height: 20),
            _buildTextSection("Have you ever really assessed how you talk to yourself? This can be a really big deal when you are hitting and have a significant effect on the outcome of your at bats. One common mistake that hitters make is thinking too much. Often this includes thoughts about your swing mechanics. The time to think about mechanics is during practice or cage work. In a game its time to trust your practice and hit!"),
            const SizedBox(height: 16),
            _buildTextSection("This is where a swing thought comes in. To be successful you do have to focus but it is important not to overload yourself with too much information. This can cause paralysis by analysis. Instead, remind yourself of a short verbal cue to keep you focused on the task at hand. This short verbal cue is what I refer to as a swing thought. Focus on what you need to do to have success and keep it simple. I like to encourage guys to write these thoughts on a small piece of paper and tape them to their bat just above the handle. This provides a focal point and a reminder of your focus when you step in the box."),
            const SizedBox(height: 16),
            _buildTextSection("Everybody is different so swing thoughts vary and yours can even change throughout the course of a season. Examples include short words or phrases such as:"),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: thoughts.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Text(t, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              )).toList(),
            ),
            const SizedBox(height: 32),
            _buildTextSection("Take some time to think about areas you may struggle. Don’t talk negative to yourself. Instead, phrase things in the positive. What are some things you need to focus on more in your at bats? Remember to keep it simple."),
            const SizedBox(height: 16),
            const Text(
              "As you record your at bats in this app, make sure to also record your swing thoughts.",
              style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSection(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 14),
    );
  }
}

class CageRoutinesScreen extends StatefulWidget {
  const CageRoutinesScreen({super.key});
  @override State<CageRoutinesScreen> createState() => _CageRoutinesScreenState();
}

class _CageRoutinesScreenState extends State<CageRoutinesScreen> {
  List<CageRoutine> _allRoutines = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  // SAVE & LOAD LOGIC
  Future<void> _saveRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_allRoutines.map((r) => r.toJson()).toList());
    await prefs.setString('cage_routines_v2', encoded);
  }

  Future<void> _loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('cage_routines_v2');
    if (saved != null) {
      final List decoded = jsonDecode(saved);
      setState(() {
        _allRoutines = decoded.map((item) => CageRoutine.fromJson(item)).toList();
      });
    }
  }

  // ADD ROUTINE DIALOG
  void _showAddRoutineDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D21),
        title: const Text("NEW CAGE ROUTINE", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: "ROUTINE NAME (E.G. TEE WORK)"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: "ENTER DRILLS & REPS..."),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _allRoutines.insert(0, CageRoutine(title: titleController.text, content: contentController.text));
                  _saveRoutines();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("SAVE", style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter the list based on search query
    final filtered = _allRoutines.where((r) => 
      r.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      r.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("CAGE ROUTINES")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        onPressed: _showAddRoutineDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: "SEARCH ROUTINES...",
                prefixIcon: Icon(Icons.search, color: Color(0xFFD4AF37)),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("NO ROUTINES FOUND", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final routine = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          title: Text(routine.title.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(routine.content, style: const TextStyle(fontSize: 14, height: 1.5)),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.share, color: Colors.blueAccent),
                                        onPressed: () => Share.share("${routine.title}\n\n${routine.content}"),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () {
                                          setState(() {
                                            _allRoutines.remove(routine);
                                            _saveRoutines();
                                          });
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
