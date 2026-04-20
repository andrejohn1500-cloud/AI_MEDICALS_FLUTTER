import 'package:flutter/material.dart';

void main() {
  runApp(const AIMedicalsApp());
}

class AIMedicalsApp extends StatelessWidget {
  const AIMedicalsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Medicals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    DiagnoseScreen(),
    HistoryScreen(),
    ProfileScreen(),
    EmergencyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Diagnose'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: 'Emergency'),
        ],
      ),
    );
  }
}

// DISCLAIMER BANNER
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        'This is a health information assistant only. Always consult a qualified healthcare professional.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
      ),
    );
  }
}

// DIAGNOSE SCREEN
class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({super.key});
  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  final _controller = TextEditingController();
  String _severity = 'Moderate';
  String _bodyArea = 'General';
  final _bodyAreas = ['General','Head','Chest','Back','Abdomen','Arms','Legs','Skin','Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const DisclaimerBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text('🩺 Symptom Triage',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 16),
                        child: Text('Describe your symptoms. Our AI will ask follow-up questions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const Text('Body Area', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _bodyArea,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      items: _bodyAreas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setState(() => _bodyArea = v!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Describe Your Symptoms *',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'e.g. I have a headache and fever for 2 days...',
                        filled: true,
                        fillColor: const Color(0xFFF0F4FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Severity', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                    Row(
                      children: ['Mild','Moderate','Severe'].map((s) => Expanded(
                        child: RadioListTile<String>(
                          title: Text(s, style: const TextStyle(fontSize: 13)),
                          value: s,
                          groupValue: _severity,
                          onChanged: (v) => setState(() => _severity = v!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
                        child: const Text('START AI TRIAGE →',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text('⚠️ For emergencies call 911/999 or use the Emergency tab',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
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

// HISTORY SCREEN
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const DisclaimerBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('🕐 Triage History',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: const [
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('No history yet', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {},
                        child: const Text('CLEAR HISTORY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
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

// PROFILE SCREEN
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const DisclaimerBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text('👤 My Profile',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)))),
                    const SizedBox(height: 16),
                    _field('Full Name', 'Enter your name'),
                    _field('Age', 'Enter your age'),
                    const Text('Blood Type', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      items: ['A+','A-','B+','B-','O+','O-','AB+','AB-']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (_) {},
                      hint: const Text('Select blood type'),
                    ),
                    const SizedBox(height: 12),
                    _field('Known Medical Conditions', 'e.g. asthma, diabetes', lines: 2),
                    _field('Allergies', 'e.g. penicillin, shellfish', lines: 2),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
                        child: const Text('SAVE PROFILE',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String hint, {int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        const SizedBox(height: 8),
        TextField(
          maxLines: lines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF0F4FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// EMERGENCY SCREEN
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const DisclaimerBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('🚨 Emergency Contacts',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                    const SizedBox(height: 16),
                    _btn('🆘 911 — EMERGENCY', const Color(0xFFD32F2F)),
                    _btn('🆘 999 — EMERGENCY', const Color(0xFFD32F2F)),
                    _btn('🚑 AMBULANCE — 784-456-1185', const Color(0xFFE65100)),
                    _btn('👮 POLICE — 784-457-1211', const Color(0xFF1565C0)),
                    _btn('🔥 FIRE — 784-456-1009', const Color(0xFFBF360C)),
                    _btn('🏥 MILTON CATO — 784-456-1185', const Color(0xFF2E7D32)),
                    const SizedBox(height: 8),
                    const Text('Tap any button to call directly',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {},
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}
