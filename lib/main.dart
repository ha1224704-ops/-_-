import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() => runApp(IraqLiveApp());

class IraqLiveApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'عراق لايف',
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: Color(0xFF0a0a0a)),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  final _user = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFCE1126), Colors.black])),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.sports_soccer, size: 80, color: Colors.white),
              SizedBox(height: 10),
              Text('عراق لايف', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('واحد عراق', style: TextStyle(color: Colors.amber, fontSize: 18)),
              SizedBox(height: 15),
              Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Text('اشهد ان لا اله الا الله\nواشهد ان محمد رسول الله\nواشهد ان عليا ولي الله', textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontSize: 16, height: 1.8))),
              SizedBox(height: 30),
              TextField(controller: _user, style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'اسمك', filled: true, fillColor: Colors.white24, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              SizedBox(height: 20),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFCE1126), minimumSize: Size(double.infinity, 54)), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(username: _user.text.isEmpty ? 'مشجع عراقي' : _user.text))), child: Text('دخول', style: TextStyle(fontSize: 19))),
            ]),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String username;
  HomePage({required this.username});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<String> favorites = [];
  List<Map<String, dynamic>> liveMatches = [];
  bool isLoading = true;
  Timer? timer;

  List<String> countries = ['العراق', 'انجلترا', 'اسبانيا', 'ايطاليا', 'المانيا', 'السعودية', 'مصر', 'دولي'];
  List<String> clubs = ['الزوراء', 'القوة الجوية', 'الشرطة', 'الطلبة', 'دهوك', 'اربيل', 'نفط البصرة', 'الميناء', 'مان سيتي', 'ارسنال', 'ليفربول', 'ريال مدريد', 'برشلونة', 'الهلال', 'النصر', 'الاهلي', 'الزمالك', 'العراق'];
  
  List<String> commentators = ['حفيظ دراجي', 'رؤوف خليف', 'عصام الشوالي', 'خليل البلوشي', 'فارس عوض'];
  List<String> qualities = ['144p', '360p', '720p HD', '1080p FHD'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    loadFavs();
    fetchRealMatches();
    timer = Timer.periodic(Duration(seconds: 30), (_) => fetchRealMatches());
  }

  loadFavs() async {
    final p = await SharedPreferences.getInstance();
    setState(() => favorites = p.getStringList('favs') ?? []);
  }

  Future<void> fetchRealMatches() async {
    setState(() => isLoading = true);
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final url = Uri.parse('https://www.thesportsdb.com/api/v1/json/3/eventsday.php?d=$today&s=Soccer');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final events = data['events'] as List?;
        if (events != null && events.isNotEmpty) {
          setState(() {
            liveMatches = events.map<Map<String, dynamic>>((e) {
              return {
                'home': e['strHomeTeam'] ?? 'فريق',
                'away': e['strAwayTeam'] ?? 'فريق',
                'time': (e['strTime'] ?? '00:00').toString().substring(0, 5),
                'league': e['strLeague'] ?? 'دوري',
                'score': (e['intHomeScore'] != null && e['intHomeScore'].toString().isNotEmpty) ? "${e['intHomeScore']} - ${e['intAwayScore']}" : "لم تبدأ",
                'live': e['strStatus'].toString().contains('Live'),
                'status': e['strStatus'] ?? 'Not Started',
              };
            }).toList();
            isLoading = false;
          });
          return;
        }
      }
      final now = DateTime.now();
      setState(() {
        liveMatches = [
          {'home': 'العراق', 'away': 'الاردن', 'time': '${now.hour}:${now.minute}', 'league': 'تصفيات كاس العالم', 'score': '0 - 0', 'live': true, 'status': 'Live'},
          {'home': 'الهلال', 'away': 'النصر', 'time': '21:00', 'league': 'دوري روشن', 'score': 'لم تبدأ', 'live': false, 'status': 'Not Started'},
          {'home': 'ريال مدريد', 'away': 'برشلونة', 'time': '22:00', 'league': 'الليغا', 'score': 'لم تبدأ', 'live': false, 'status': 'Not Started'},
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عراق لايف - ${widget.username}', style: TextStyle(fontSize: 14)),
        backgroundColor: Colors.black,
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: fetchRealMatches)],
        bottom: TabBar(controller: _tab, isScrollable: true, labelColor: Colors.amber, tabs: [Tab(text: 'المباشر'), Tab(text: 'البلدان'), Tab(text: 'المفضلة'), Tab(text: 'الاعدادات')]),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          isLoading ? Center(child: CircularProgressIndicator(color: Colors.red)) : ListView.builder(itemCount: liveMatches.length, itemBuilder: (_, i) {
            final m = liveMatches[i];
            return Card(color: m['live'] == true ? Color(0xFFCE1126) : Colors.white10, margin: EdgeInsets.all(8), child: ListTile(
              title: Text('${m['home']} vs ${m['away']}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('${m['league']} - ${m['time']} - ${m['score']}', style: TextStyle(color: Colors.white70, fontSize: 11)),
              trailing: m['live'] == true ? Container(padding: EdgeInsets.all(4), color: Colors.white, child: Text('مباشر', style: TextStyle(color: Colors.red, fontSize: 10))) : Text(m['score'].toString(), style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchScreen(match: m, commentators: commentators, qualities: qualities))),
            ));
          }),
          ListView(children: countries.map((c) => ExpansionTile(title: Text(c, style: TextStyle(color: Colors.white)), children: clubs.map((club) => ListTile(title: Text(club, style: TextStyle(color: Colors.white70)), trailing: IconButton(icon: Icon(favorites.contains(club) ? Icons.star : Icons.star_border, color: Colors.amber), onPressed: () async { final p = await SharedPreferences.getInstance(); setState(() { if (favorites.contains(club)) { favorites.remove(club); } else { favorites.add(club); }}); p.setStringList('favs', favorites); }))).toList())).toList()),
          favorites.isEmpty ? Center(child: Text('لا يوجد مفضلة', style: TextStyle(color: Colors.white54))) : ListView(children: favorites.map((e) => ListTile(title: Text(e, style: TextStyle(color: Colors.white)), leading: Icon(Icons.favorite, color: Colors.red))).toList()),
          ListView(children: [
            ListTile(title: Text('اسم الحزمة', style: TextStyle(color: Colors.white)), subtitle: Text('com.iraqlive.wahediraq', style: TextStyle(color: Colors.amber))),
            ListTile(title: Text('عن التطبيق', style: TextStyle(color: Colors.white)), subtitle: Text('عراق لايف 2.0 - واحد عراق - بث حقيقي', style: TextStyle(color: Colors.white70))),
          ]),
        ],
      ),
    );
  }
}

class MatchScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  final List<String> commentators, qualities;
  MatchScreen({required this.match, required this.commentators, required this.qualities});
  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  String selC = '';
  String selQ = '720p HD';
  @override
  void initState() { super.initState(); selC = widget.commentators.first; }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.match['home']} vs ${widget.match['away']}', style: TextStyle(fontSize: 13))),
      body: Column(children: [
        AspectRatio(aspectRatio: 16/9, child: Container(color: Colors.black, child: Center(child: Icon(Icons.live_tv, size: 60, color: Colors.white24)))),
        Expanded(child: ListView(padding: EdgeInsets.all(16), children: [
          Text('المعلق:', style: TextStyle(color: Colors.amber)),
          DropdownButton<String>(isExpanded: true, value: selC, items: widget.commentators.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => selC = v!)),
          SizedBox(height: 12),
          Text('الجودة:', style: TextStyle(color: Colors.amber)),
          Wrap(spacing: 6, children: widget.qualities.map((q) => ChoiceChip(label: Text(q), selected: selQ == q, selectedColor: Colors.red, onSelected: (_) => setState(() => selQ = q))).toList()),
          SizedBox(height: 20),
          ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: Size(double.infinity, 48)), onPressed: () {}, icon: Icon(Icons.play_arrow), label: Text('تشغيل - $selC')),
        ])),
      ]),
    );
  }
}