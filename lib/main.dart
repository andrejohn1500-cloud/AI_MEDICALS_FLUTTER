import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';

void main() => runApp(const AIMedicalsApp());

const kGroqKey = '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';
const kGroqUrl = 'https://api.groq.com/openai/v1/chat/completions';
const kBlue = Color(0xFF1565C0);
const kRed = Color(0xFFD32F2F);

class AIMedicalsApp extends StatelessWidget {
  const AIMedicalsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Medicals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: kBlue), useMaterial3: true),
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
  int _idx = 0;
  @override
  Widget build(BuildContext context) {
    final screens = [const DiagnoseScreen(), const HistoryScreen(), const ProfileScreen(), const EmergencyScreen()];
    return Scaffold(
      body: screens[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kBlue,
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

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text('This is a health information assistant only. Always consult a qualified healthcare professional.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF795548))),
    );
  }
}

// ─── GROQ API ────────────────────────────────────────────────
Future<String> callGroq(List<Map<String,String>> messages) async {
  final res = await http.post(
    Uri.parse(kGroqUrl),
    headers: {'Authorization': 'Bearer $kGroqKey', 'Content-Type': 'application/json'},
    body: jsonEncode({'model': 'llama-3.3-70b-versatile', 'messages': messages, 'max_tokens': 1024, 'temperature': 0.7}),
  );
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return data['choices'][0]['message']['content'];
  }
  return 'Sorry, I could not get a response. Please try again.';
}

// ─── DIAGNOSE ────────────────────────────────────────────────
class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({super.key});
  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  final _ctrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _severity = 'Moderate';
  String _body = 'General';
  bool _chatMode = false;
  bool _loading = false;
  List<Map<String, String>> _messages = [];
  final _bodies = ['General','Head','Chest','Back','Abdomen','Arms','Legs','Skin','Other'];
  final _scroll = ScrollController();

  Future<void> _startTriage() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _chatMode = true; });
    _messages = [
      {'role': 'system', 'content': 'You are a professional medical triage assistant. A patient describes symptoms. Ask focused follow-up questions one at a time to gather more details. After 3-4 questions, provide a structured assessment with: Top 3 possible conditions with likelihood %, recommended actions, urgency level (Low/Medium/High/Emergency), and when to seek immediate care. Always remind the patient to consult a real doctor. Body area: $_body. Severity: $_severity.'},
      {'role': 'user', 'content': _ctrl.text.trim()},
    ];
    final reply = await callGroq(_messages);
    _messages.add({'role': 'assistant', 'content': reply});
    
    // Save to history
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('history') ?? [];
    history.insert(0, jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'symptom': _ctrl.text.trim(),
      'body': _body,
      'severity': _severity,
      'response': reply,
    }));
    if (history.length > 50) history.removeLast();
    await prefs.setStringList('history', history);
    
    setState(() => _loading = false);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    final msg = _msgCtrl.text.trim();
    _msgCtrl.clear();
    _messages.add({'role': 'user', 'content': msg});
    setState(() => _loading = true);
    final reply = await callGroq(_messages);
    _messages.add({'role': 'assistant', 'content': reply});
    setState(() => _loading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _reset() {
    setState(() { _chatMode = false; _messages = []; _ctrl.clear(); _severity = 'Moderate'; _body = 'General'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const DisclaimerBanner(),
          if (!_chatMode) Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(child: Text('🩺 Symptom Triage', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kBlue))),
              const Center(child: Padding(padding: EdgeInsets.only(top: 4, bottom: 16),
                child: Text('Describe your symptoms. Our AI will ask follow-up questions.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))),
              const Text('Body Area', style: TextStyle(fontWeight: FontWeight.bold, color: kBlue)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(value: _body,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: _bodies.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => _body = v!)),
              const SizedBox(height: 16),
              const Text('Describe Your Symptoms *', style: TextStyle(fontWeight: FontWeight.bold, color: kBlue)),
              const SizedBox(height: 8),
              TextField(controller: _ctrl, maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'e.g. I have a headache and fever for 2 days...',
                  filled: true, fillColor: const Color(0xFFF0F4FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              const Text('Severity', style: TextStyle(fontWeight: FontWeight.bold, color: kBlue)),
              const SizedBox(height: 8),
              Row(children: ['Mild','Moderate','Severe'].map((s) => Expanded(
                child: InkWell(
                  onTap: () => setState(() => _severity = s),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Radio<String>(value: s, groupValue: _severity, onChanged: (v) => setState(() => _severity = v!)),
                    Text(s, style: const TextStyle(fontSize: 13)),
                  ])))).toList()),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _loading ? null : _startTriage,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) :
                    const Text('START AI TRIAGE →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
              const SizedBox(height: 12),
              const Center(child: Text('⚠️ For emergencies call 911/999 or use the Emergency tab', style: TextStyle(color: Colors.red, fontSize: 12))),
            ]),
          )),
          if (_chatMode) Expanded(child: Column(children: [
            Container(color: kBlue, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                const Expanded(child: Text('🩺 AI Triage Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _reset),
              ])),
            Expanded(child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.where((m) => m['role'] != 'system').length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                final msgs = _messages.where((m) => m['role'] != 'system').toList();
                if (_loading && i == msgs.length) {
                  return const Align(alignment: Alignment.centerLeft,
                    child: Padding(padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator()));
                }
                final msg = msgs[i];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? kBlue : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12)),
                    child: Text(msg['content'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14))));
              })),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)]),
              child: Row(children: [
                Expanded(child: TextField(controller: _msgCtrl,
                  decoration: InputDecoration(hintText: 'Type your response...',
                    filled: true, fillColor: const Color(0xFFF0F4FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
                const SizedBox(width: 8),
                CircleAvatar(backgroundColor: kBlue,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _loading ? null : _sendMessage)),
              ])),
          ])),
        ]),
      ),
    );
  }
}

// ─── HISTORY ────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String,dynamic>> _history = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('history') ?? [];
    setState(() => _history = raw.map((e) => jsonDecode(e) as Map<String,dynamic>).toList());
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
    setState(() => _history = []);
  }

  String _fmt(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const DisclaimerBanner(),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('🕐 Triage History', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kBlue)),
              const SizedBox(height: 16),
              Expanded(child: _history.isEmpty
                ? const Center(child: Text('No history yet', style: TextStyle(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (ctx, i) {
                      final h = _history[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text(h['symptom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${h['body']} • ${h['severity']} • ${_fmt(h['date'])}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          children: [
                            Padding(padding: const EdgeInsets.all(12),
                              child: Text(h['response'] ?? '', style: const TextStyle(fontSize: 13)))
                          ],
                        ));
                    })),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _clear,
                  child: const Text('CLEAR HISTORY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ─── PROFILE ────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _conditions = TextEditingController();
  final _allergies = TextEditingController();
  String? _blood;
  String _homeCountry = 'St. Vincent and the Grenadines';
  String _currentCountry = 'St. Vincent and the Grenadines';
  String? _photoPath;
  final _bloods = ['A+','A-','B+','B-','O+','O-','AB+','AB-'];
  final _countries = ['St. Vincent and the Grenadines','Barbados','Trinidad and Tobago','Jamaica','Guyana','Antigua and Barbuda','St. Lucia','Grenada','Dominica','St. Kitts and Nevis','Bahamas','Haiti','Cuba','Dominican Republic','Puerto Rico (US)','Aruba','Curacao','Sint Maarten','Suriname','Belize','Montserrat','Cayman Islands','Brazil','Colombia','Venezuela','Peru','Argentina','Chile','Ecuador','Bolivia','Paraguay','Uruguay','United States','Canada','United Kingdom','Australia','India','Nigeria'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _name.text = p.getString('name') ?? '';
      _age.text = p.getString('age') ?? '';
      _conditions.text = p.getString('conditions') ?? '';
      _allergies.text = p.getString('allergies') ?? '';
      _blood = p.getString('blood');
      _homeCountry = p.getString('homeCountry') ?? 'St. Vincent and the Grenadines';
      _currentCountry = p.getString('currentCountry') ?? 'St. Vincent and the Grenadines';
      _photoPath = p.getString('photoPath');
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('name', _name.text);
    await p.setString('age', _age.text);
    await p.setString('conditions', _conditions.text);
    await p.setString('allergies', _allergies.text);
    if (_blood != null) await p.setString('blood', _blood!);
    await p.setString('homeCountry', _homeCountry);
    await p.setString('currentCountry', _currentCountry);
    if (_photoPath != null) await p.setString('photoPath', _photoPath!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Profile saved!'), backgroundColor: kBlue));
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _photoPath = img.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const DisclaimerBanner(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(child: Text('👤 My Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kBlue))),
              const SizedBox(height: 16),
              // Profile Photo
              Center(child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(children: [
                  CircleAvatar(radius: 50,
                    backgroundColor: const Color(0xFFF0F4FF),
                    backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                    child: _photoPath == null ? const Icon(Icons.person, size: 50, color: kBlue) : null),
                  Positioned(bottom: 0, right: 0,
                    child: CircleAvatar(radius: 16, backgroundColor: kBlue,
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white))),
                ]),
              )),
              const SizedBox(height: 8),
              const Center(child: Text('Tap photo to change', style: TextStyle(color: Colors.grey, fontSize: 12))),
              const SizedBox(height: 16),
              _lbl('Full Name'), _tf(_name, 'Enter your name'),
              _lbl('Age'), _tf(_age, 'Enter your age', num: true),
              _lbl('Blood Type'),
              DropdownButtonFormField<String>(
                value: _blood,
                decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF0F4FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                hint: const Text('Select blood type'),
                items: _bloods.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _blood = v)),
              const SizedBox(height: 12),
              _lbl('Known Medical Conditions'),
              _tf(_conditions, 'e.g. asthma, diabetes', lines: 2),
     
