import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Firebase Imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDbr2DwQcrvj2ZAExwC9gJE_UbIWDcMzPU",
      appId: "1:299128321546:web:0e105ff33bbb2a6e8ad1f3",
      messagingSenderId: "299128321546",
      projectId: "digitalhisab-ae364",
      authDomain: "digitalhisab-ae364.firebaseapp.com",
      storageBucket: "digitalhisab-ae364.firebasestorage.app",
      measurementId: "G-EFZG183W2Z",
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  List<String> regUsers = prefs.getStringList('registered_users') ?? [];

  for (String email in regUsers) {
    String pass = prefs.getString('user_pass_$email') ?? '123';
    String uname = prefs.getString('user_name_$email') ?? email;
    String? uAvatar = prefs.getString('user_avatar_$email');
    String sixDigitId = prefs.getString('user_six_id_$email') ?? '123456';

    String? wJson = prefs.getString('user_wallets_$email');
    Map<String, double> wallets = {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0};
    if (wJson != null) {
      wallets = Map<String, double>.from(jsonDecode(wJson));
    } else {
      double oldBalance = prefs.getDouble('user_balance_$email') ?? 100000.0;
      wallets['Cash'] = oldBalance;
    }

    String goalTitle = prefs.getString('user_goal_title_$email') ?? 'Emergency Fund';
    double goalTarget = prefs.getDouble('user_goal_target_$email') ?? 50000.0;

    List<String> customCategories = prefs.getStringList('user_categories_$email') ??
        ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other'];

    String? expJson = prefs.getString('user_expenses_$email');
    List<ExpenseItem> expenses = [];
    if (expJson != null) {
      List decoded = jsonDecode(expJson);
      expenses = decoded.map((e) => ExpenseItem.fromMap(e)).toList();
    }

    String? subJson = prefs.getString('user_subs_$email');
    List<SubscriptionItem> subscriptions = [];
    if (subJson != null) {
      List decoded = jsonDecode(subJson);
      subscriptions = decoded.map((e) => SubscriptionItem.fromMap(e)).toList();
    }

    String? udhJson = prefs.getString('user_udhaar_$email');
    List<UdhaarItem> udhaar = [];
    if (udhJson != null) {
      List decoded = jsonDecode(udhJson);
      udhaar = decoded.map((e) => UdhaarItem.fromMap(e)).toList();
    }

    String? splitJson = prefs.getString('user_splits_$email');
    List<SplitGroup> splits = [];
    if (splitJson != null) {
      List decoded = jsonDecode(splitJson);
      splits = decoded.map((e) => SplitGroup.fromMap(e)).toList();
    }

    String? assetJson = prefs.getString('user_assets_$email');
    List<AssetItem> assets = [];
    if (assetJson != null) {
      List decoded = jsonDecode(assetJson);
      assets = decoded.map((e) => AssetItem.fromMap(e)).toList();
    }

    String? billsJson = prefs.getString('user_bills_$email');
    List<BillItem> bills = [];
    if (billsJson != null) {
      List decoded = jsonDecode(billsJson);
      bills = decoded.map((e) => BillItem.fromMap(e)).toList();
    }

    UserDatabase.users[email] = {
      'name': uname,
      'password': pass,
      'sixDigitId': sixDigitId,
      'mobile': email,
      'avatar': uAvatar,
      'wallets': wallets,
      'goalTitle': goalTitle,
      'goalTarget': goalTarget,
      'customCategories': customCategories,
      'expenses': expenses,
      'subscriptions': subscriptions,
      'udhaar': udhaar,
      'splits': splits,
      'assets': assets,
      'bills': bills,
    };
  }

  final String? savedUserEmail = prefs.getString('logged_in_user');
  final bool initialDarkMode = prefs.getBool('is_dark_mode') ?? false;
  final String? savedLang = prefs.getString('app_language');
  if (savedLang != null) AppLocale.currentLang = savedLang;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(GoluKaKharchApp(
    initialUserEmail: savedUserEmail,
    initialDarkMode: initialDarkMode,
  ));
}

// ==================== ANIMATED FINTECH HEADER BACKGROUND ====================
class AnimatedFintechHeader extends StatefulWidget {
  final Widget child;
  final double height;
  const AnimatedFintechHeader({super.key, required this.child, this.height = 310});

  @override
  State<AnimatedFintechHeader> createState() => _AnimatedFintechHeaderState();
}

class _AnimatedFintechHeaderState extends State<AnimatedFintechHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        return Container(
          width: double.infinity,
          height: widget.height,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _FintechMeshPainter(progress: progress))),
                widget.child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FintechMeshPainter extends CustomPainter {
  final double progress;
  _FintechMeshPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final double angle = progress * 2 * math.pi;
    final gradient = LinearGradient(
      begin: Alignment(math.cos(angle) * 0.8 - 0.2, math.sin(angle) * 0.8 - 0.2),
      end: Alignment(-math.cos(angle) * 0.8 + 0.2, -math.sin(angle) * 0.8 + 0.2),
      colors: const [Color(0xFF1E0A4E), Color(0xFF380B7A), Color(0xFF5A14A8), Color(0xFF280654)],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    final orb1Center = Offset(
      size.width * 0.8 + math.sin(progress * 2 * math.pi) * 45,
      size.height * 0.3 + math.cos(progress * 2 * math.pi) * 35,
    );
    canvas.drawCircle(
      orb1Center,
      130,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF00E5FF).withOpacity(0.28),
          const Color(0xFF00E5FF).withOpacity(0.0),
        ]).createShader(Rect.fromCircle(center: orb1Center, radius: 130))
        ..blendMode = BlendMode.screen,
    );

    final orb2Center = Offset(
      size.width * 0.2 + math.cos(progress * 2 * math.pi) * 50,
      size.height * 0.65 + math.sin(progress * 2 * math.pi) * 30,
    );
    canvas.drawCircle(
      orb2Center,
      150,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFF007F).withOpacity(0.22),
          const Color(0xFFFF007F).withOpacity(0.0),
        ]).createShader(Rect.fromCircle(center: orb2Center, radius: 150))
        ..blendMode = BlendMode.screen,
    );

    final orb3Center = Offset(
      size.width * 0.5 + math.sin(progress * 4 * math.pi) * 30,
      size.height * 0.2 + math.cos(progress * 4 * math.pi) * 20,
    );
    canvas.drawCircle(
      orb3Center,
      95,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFD700).withOpacity(0.18),
          const Color(0xFFFFD700).withOpacity(0.0),
        ]).createShader(Rect.fromCircle(center: orb3Center, radius: 95))
        ..blendMode = BlendMode.screen,
    );

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    for (double x = 0; x <= size.width; x += 10) {
      path.lineTo(
        x,
        size.height * 0.68 + math.sin((x / size.width * 2 * math.pi) + (progress * 2 * math.pi)) * 18,
      );
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _FintechMeshPainter oldDelegate) => oldDelegate.progress != progress;
}

// ==================== DATA MODELS ====================
class UserDatabase {
  static final Map<String, Map<String, dynamic>> users = {};
}

class ExpenseItem {
  String id, title, type, date, time, category, wallet;
  double amount;
  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    this.type = 'Expense',
    required this.date,
    required this.time,
    required this.category,
    this.wallet = 'Cash',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type,
        'date': date,
        'time': time,
        'category': category,
        'wallet': wallet,
      };

  factory ExpenseItem.fromMap(Map<String, dynamic> map) => ExpenseItem(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        amount: (map['amount'] ?? 0.0).toDouble(),
        type: map['type'] ?? 'Expense',
        date: map['date'] ?? '',
        time: map['time'] ?? '',
        category: map['category'] ?? 'Other',
        wallet: map['wallet'] ?? 'Cash',
      );
}

class SubscriptionItem {
  String id, title, billDate;
  double amount;
  SubscriptionItem({required this.id, required this.title, required this.amount, required this.billDate});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'amount': amount, 'billDate': billDate};

  factory SubscriptionItem.fromMap(Map<String, dynamic> map) => SubscriptionItem(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        amount: (map['amount'] ?? 0.0).toDouble(),
        billDate: map['billDate'] ?? '',
      );
}

class BillItem {
  String id, title, purchaseDate, warrantyDate, imageBase64;
  BillItem({
    required this.id,
    required this.title,
    required this.purchaseDate,
    required this.warrantyDate,
    required this.imageBase64,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'purchaseDate': purchaseDate,
        'warrantyDate': warrantyDate,
        'imageBase64': imageBase64,
      };

  factory BillItem.fromMap(Map<String, dynamic> map) => BillItem(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        purchaseDate: map['purchaseDate'] ?? '',
        warrantyDate: map['warrantyDate'] ?? '',
        imageBase64: map['imageBase64'] ?? '',
      );
}

class UdhaarItem {
  String id, personName, type, date, dueDate;
  double amount;
  bool isSettled;

  UdhaarItem({
    required this.id,
    required this.personName,
    required this.amount,
    required this.type,
    required this.date,
    required this.dueDate,
    this.isSettled = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'personName': personName,
        'amount': amount,
        'type': type,
        'date': date,
        'dueDate': dueDate,
        'isSettled': isSettled,
      };

  factory UdhaarItem.fromMap(Map<String, dynamic> map) => UdhaarItem(
        id: map['id'] ?? '',
        personName: map['personName'] ?? '',
        amount: (map['amount'] ?? 0.0).toDouble(),
        type: map['type'] ?? 'GIVE',
        date: map['date'] ?? '',
        dueDate: map['dueDate'] ?? map['date'] ?? '',
        isSettled: map['isSettled'] ?? false,
      );
}

class SplitGroup {
  String id, groupName;
  double totalAmount;
  int membersCount;

  SplitGroup({required this.id, required this.groupName, required this.totalAmount, required this.membersCount});

  Map<String, dynamic> toMap() => {
        'id': id,
        'groupName': groupName,
        'totalAmount': totalAmount,
        'membersCount': membersCount,
      };

  factory SplitGroup.fromMap(Map<String, dynamic> map) => SplitGroup(
        id: map['id'] ?? '',
        groupName: map['groupName'] ?? '',
        totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
        membersCount: map['membersCount'] ?? 1,
      );
}

class AssetItem {
  String id, assetName;
  double assetValue;

  AssetItem({required this.id, required this.assetName, required this.assetValue});

  Map<String, dynamic> toMap() => {'id': id, 'assetName': assetName, 'assetValue': assetValue};

  factory AssetItem.fromMap(Map<String, dynamic> map) => AssetItem(
        id: map['id'] ?? '',
        assetName: map['assetName'] ?? '',
        assetValue: (map['assetValue'] ?? 0.0).toDouble(),
      );
}

// ==================== APP ROOT & LOCALIZATION ====================
class GoluKaKharchApp extends StatefulWidget {
  final String? initialUserEmail;
  final bool initialDarkMode;

  const GoluKaKharchApp({
    super.key,
    this.initialUserEmail,
    required this.initialDarkMode,
  });

  @override
  State<GoluKaKharchApp> createState() => _GoluKaKharchAppState();

  static _GoluKaKharchAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_GoluKaKharchAppState>();
}

class _GoluKaKharchAppState extends State<GoluKaKharchApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  void toggleTheme() async {
    setState(() => _isDarkMode = !_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  void changeLanguage(String langCode) {
    setState(() => AppLocale.currentLang = langCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DigitalHisab',
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        cardColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: widget.initialUserEmail != null && UserDatabase.users.containsKey(widget.initialUserEmail)
          ? HomePage(userEmail: widget.initialUserEmail!)
          : const WelcomeScreen(),
    );
  }
}

// ==================== WELCOME / LOGIN OPTIONS SCREEN ====================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocale.tr('select_lang'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: AppLocale.languages.entries.map((entry) {
                  bool isSelected = AppLocale.currentLang == entry.key;
                  return ListTile(
                    dense: true,
                    leading: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.deepPurple : Colors.grey),
                    title: Text(entry.value,
                        style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.deepPurple : Colors.black87)),
                    onTap: () {
                      GoluKaKharchApp.of(context)?.changeLanguage(entry.key);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileOtpLoginDialog(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    bool otpSent = false;
    String verificationId = "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Mobile OTP Login'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!otpSent) ...[
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Enter Mobile Number', border: OutlineInputBorder(), prefixText: '+91 '),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
                    onPressed: () async {
                      String phone = phoneCtrl.text.trim();
                      if (phone.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid 10-digit mobile number!'), backgroundColor: Colors.red));
                        return;
                      }

                      // Real Firebase Phone Auth
                      try {
                        await FirebaseAuth.instance.verifyPhoneNumber(
                          phoneNumber: '+91$phone',
                          verificationCompleted: (PhoneAuthCredential credential) async {
                            // Auto-resolution on Android devices if applicable
                            await FirebaseAuth.instance.signInWithCredential(credential);
                          },
                          verificationFailed: (FirebaseAuthException e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Verification Failed: ${e.message}'), backgroundColor: Colors.red));
                          },
                          codeSent: (String verId, int? resendToken) {
                            verificationId = verId;
                            setDialogState(() {
                              otpSent = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('OTP sent to your phone!'), backgroundColor: Colors.green));
                          },
                          codeAutoRetrievalTimeout: (String verId) {
                            verificationId = verId;
                          },
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: const Text('Send OTP'),
                  ),
                ] else ...[
                  Text('OTP sent to +91 ${phoneCtrl.text.trim()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Enter 6-Digit OTP', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    onPressed: () async {
                      try {
                        String smsCode = otpCtrl.text.trim();
                        if (smsCode.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter valid 6-digit OTP!'), backgroundColor: Colors.red));
                          return;
                        }

                        PhoneAuthCredential credential = PhoneAuthProvider.credential(
                          verificationId: verificationId,
                          smsCode: smsCode,
                        );

                        UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
                        String mobile = phoneCtrl.text.trim();
                        String userEmail = userCred.user?.email ?? "$mobile@digitalhisab.com";

                        final docRef = FirebaseFirestore.instance.collection('users_data').doc(userEmail);
                        final docSnap = await docRef.get();
                        if (!docSnap.exists) {
                          String sixDigitId = (100000 + math.Random().nextInt(900000)).toString();
                          await docRef.set({
                            'name': 'User $mobile',
                            'password': '123',
                            'sixDigitId': sixDigitId,
                            'mobile': mobile,
                            'avatar': null,
                            'wallets': {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0},
                            'goalTitle': 'Emergency Fund',
                            'goalTarget': 50000.0,
                            'customCategories': ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other'],
                            'expenses': [],
                            'subscriptions': [],
                            'udhaar': [],
                            'splits': [],
                            'assets': [],
                            'bills': [],
                          });
                        }

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('logged_in_user', userEmail);

                        final freshSnap = await docRef.get();
                        final freshData = freshSnap.data() as Map<String, dynamic>?;

                        UserDatabase.users[userEmail] = {
                          'name': freshData?['name'] ?? 'User $mobile',
                          'password': freshData?['password'] ?? '123',
                          'sixDigitId': freshData?['sixDigitId'] ?? '123456',
                          'mobile': mobile,
                          'avatar': freshData?['avatar'],
                          'wallets': freshData?['wallets'] != null
                              ? Map<String, double>.from(freshData!['wallets'])
                              : {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0},
                          'goalTitle': freshData?['goalTitle'] ?? 'Emergency Fund',
                          'goalTarget': (freshData?['goalTarget'] ?? 50000.0).toDouble(),
                          'customCategories': freshData?['customCategories'] != null
                              ? List<String>.from(freshData!['customCategories'])
                              : ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other'],
                          'expenses': (freshData?['expenses'] as List? ?? []).map((e) => ExpenseItem.fromMap(e)).toList(),
                          'subscriptions': (freshData?['subscriptions'] as List? ?? []).map((e) => SubscriptionItem.fromMap(e)).toList(),
                          'udhaar': (freshData?['udhaar'] as List? ?? []).map((e) => UdhaarItem.fromMap(e)).toList(),
                          'splits': (freshData?['splits'] as List? ?? []).map((e) => SplitGroup.fromMap(e)).toList(),
                          'assets': (freshData?['assets'] as List? ?? []).map((e) => AssetItem.fromMap(e)).toList(),
                          'bills': (freshData?['bills'] as List? ?? []).map((e) => BillItem.fromMap(e)).toList(),
                        };

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (context) => HomePage(userEmail: userEmail)));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid OTP or Login Failed: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: const Text('Verify & Login'),
                  ),
                ],
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F109E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F109E), Color(0xFF7A21D5), Color(0xFF280654)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton.icon(
                    onPressed: () => _showLanguageSelector(context),
                    icon: const Icon(Icons.language, color: Colors.white70, size: 18),
                    label: Text(AppLocale.languages[AppLocale.currentLang]?.split(' ')[0] ?? 'English',
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ),
                const Spacer(),
                Center(
                  child: SizedBox(
                    height: 75,
                    width: 75,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 24,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                        ),
                        const Icon(Icons.account_balance, size: 60, color: Color(0xFFFFD700)),
                        const Positioned(
                          top: 20,
                          child: Icon(Icons.currency_rupee, size: 22, color: Color(0xFF280654)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to DigitalHisab !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your daily expenses securely',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen(isGoogleLogin: true)));
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                  label: const Text('Login with Google Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _showMobileOtpLoginDialog(context),
                  icon: const Icon(Icons.phone_android, color: Colors.white),
                  label: const Text('Login with Mobile Number (OTP)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
                  },
                  icon: const Icon(Icons.email_outlined, color: Colors.blueAccent),
                  label: const Text('Login with Email and Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Colors.white38),
                  ),
                  onPressed: () async {
                    String guestEmail = "guest_${DateTime.now().millisecondsSinceEpoch}@digitalhisab.com";
                    UserDatabase.users[guestEmail] = {
                      'name': 'Guest User',
                      'password': '123',
                      'sixDigitId': '000000',
                      'mobile': guestEmail,
                      'avatar': null,
                      'wallets': {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0},
                      'goalTitle': 'Emergency Fund',
                      'goalTarget': 50000.0,
                      'customCategories': ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other'],
                      'expenses': <ExpenseItem>[],
                      'subscriptions': <SubscriptionItem>[],
                      'udhaar': <UdhaarItem>[],
                      'splits': <SplitGroup>[],
                      'assets': <AssetItem>[],
                      'bills': <BillItem>[],
                    };
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('logged_in_user', guestEmail);
                    if (!context.mounted) return;
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(userEmail: guestEmail)));
                  },
                  child: const Text("Skip", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Center(
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Why is it needed?'),
                          content: const Text(
                              'Logging in allows your financial data, expenses, and udhaar accounts to securely sync to the cloud so you never lose them across devices or app uninstalls.'),
                          actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
                        ),
                      );
                    },
                    child: const Text('Why is it needed?', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PRIVACY POLICY SCREEN ====================
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFF3F109E),
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3F109E))),
            SizedBox(height: 8),
            Text('This policy is effective as of 2026-09-05', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 16),
            Text(
                'Fimlly Pvt Ltd has built the DigitalHisab app as a Free app. This SERVICE is provided by Fimlly Pvt Ltd at no cost and is intended for use as is.',
                style: TextStyle(height: 1.4)),
            SizedBox(height: 16),
            Text('Personal Information Collected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                '• Phone Number: Used for account verification and expense groups.\n• Email Address: Used for registration, recovery, and communication.\n• Images/Photos: Used to personalize your profile avatar and bills.',
                style: TextStyle(height: 1.4)),
            SizedBox(height: 16),
            Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                'We value your trust in providing us your Personal Information, thus we strive to use commercially acceptable means of protecting it.',
                style: TextStyle(height: 1.4)),
            SizedBox(height: 20),
            Text('Contact Us', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                'If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at support@hisabkitab-app.com.',
                style: TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class AppLocale {
  static String currentLang = 'en';
  static const Map<String, String> languages = {
    'hi': 'हिन्दी (Hindi)',
    'en': 'English',
    'mr': 'मराठी (Marathi)',
    'bho': 'भोजपुरी (Bhojpuri)'
  };
  static const Map<String, Map<String, String>> dict = {
    'en': {
      'app_title': 'DigitalHisab',
      'sub_login': 'Login to your account',
      'sub_reg': 'Create your new panel',
      'name': 'Your Name',
      'name_hint': 'Enter your full name',
      'phone_email': 'Mobile Number / Email',
      'password': 'Password',
      'login': 'Login',
      'register': 'Register & Create Panel',
      'no_acc': "Don't have an account? Create new",
      'have_acc': 'Already have an account? Login',
      'net_balance': 'Net Balance',
      'month_expense': 'This Month Expense',
      'goal_title_prefix': 'Goal:',
      'savings_label': 'Savings:',
      'target_label': 'Target:',
      'expense': 'Expense',
      'income': 'Income',
      'title_note_label': 'Title / Note',
      'title_hint': 'e.g. milk, electricity bill, room rent',
      'amount_label': 'Amount',
      'date_label': 'Date',
      'add_tx_btn': '+ Add Transaction',
      'search_hint': 'Search transaction...',
      'recent_title': 'Recent Transactions',
      'no_tx_found': 'No transactions found!',
      'udhaar_title': 'Udhaar Khata (Dues)',
      'lena_hai': 'Lena Hai (You\'ll Get)',
      'dena_hai': 'Dena Hai (You\'ll Pay)',
      'new_udhaar': 'Add New Udhaar',
      'gave_money': 'I Gave (To Collect)',
      'took_money': 'I Took (To Return)',
      'person_name_hint': 'Person Name',
      'amount_hint': 'Amount (₹)',
      'save_udhaar': 'Save Udhaar',
      'past_dues': 'Previous Udhaar Records',
      'no_dues': 'No udhaar records yet.',
      'settled_badge': '(Settled)',
      'reopen_tooltip': 'Reopen',
      'settle_tooltip': 'Mark Settled',
      'settings_title': 'Master Settings & Controls',
      'change_lang_opt': 'App Language',
      'dark_mode': 'Dark Mode',
      'dark_mode_sub': 'Switch between Light and Dark themes',
      'update_name_title': 'Update Profile Name',
      'save_name': 'Save Name',
      'change_password': 'Change Account Password',
      'current_pass': 'Current Password',
      'new_pass': 'New Password',
      'update_pass': 'Update Password',
      'statement_title': 'Financial Statement Report',
      'copy_report': 'Copy Report',
      'export_csv': 'Export as CSV',
      'close': 'Close',
      'breakdown_title': 'Category-wise Spending Breakdown',
      'limit_label': 'Limit:',
      'select_lang': 'Select Language',
    },
    'hi': {
      'app_title': 'DigitalHisab',
      'sub_login': 'अपने अकाउंट में लॉगिन करें',
      'sub_reg': 'अपना नया पैनल बनाएं',
      'name': 'आपका नाम',
      'name_hint': 'अपना पूरा नाम लिखें',
      'phone_email': 'मोबाइल नंबर / ईमेल',
      'password': 'पासवर्ड',
      'login': 'लॉगिन करें',
      'register': 'रजिस्टर करें',
      'no_acc': 'अकाउंट नहीं है? नया बनाएं',
      'have_acc': 'पहले से अकाउंट है? लॉगिन करें',
      'net_balance': 'कुल बैलेंस',
      'month_expense': 'इस महीने का खर्च',
      'goal_title_prefix': 'लक्ष्य:',
      'savings_label': 'बचत:',
      'target_label': 'लक्ष्य:',
      'expense': 'खर्च',
      'income': 'कमाई',
      'title_note_label': 'नाम / विवरण',
      'title_hint': 'उदा. दूध, बिजली बिल',
      'amount_label': 'रक्कम',
      'date_label': 'तारीख',
      'add_tx_btn': '+ लेन-देन जोड़ें',
      'search_hint': 'लेन-देन खोजें...',
      'recent_title': 'हाल के लेन-देन',
      'no_tx_found': 'कोई लेन-देन नहीं मिला!',
      'udhaar_title': 'उधार खाता',
      'lena_hai': 'लेना है',
      'dena_hai': 'देना है',
      'new_udhaar': 'नया उधार जोड़ें',
      'gave_money': 'मैंने दिया',
      'took_money': 'मैंने लिया',
      'person_name_hint': 'व्यक्ति का नाम',
      'amount_hint': 'रक्कम (₹)',
      'save_udhaar': 'उधार सहेजें',
      'past_dues': 'पुराना उधार हिसाब',
      'no_dues': 'कोई उधार रिकॉर्ड नहीं है।',
      'settled_badge': '(चुक्ता)',
      'reopen_tooltip': 'पुनः खोलें',
      'settle_tooltip': 'चुक्ता चिह्नित करें',
      'settings_title': 'मास्टर सेटिंग्स',
      'change_lang_opt': 'ऐप की भाषा बदलें',
      'dark_mode': 'डार्क मोड',
      'dark_mode_sub': 'लाइट और डार्क थीम बदलें',
      'update_name_title': 'प्रोफाइल नाम बदलें',
      'save_name': 'नाम सहेजें',
      'change_password': 'अकाउंट पासवर्ड बदलें',
      'current_pass': 'वर्तमान पासवर्ड',
      'new_pass': 'नया पासवर्ड',
      'update_pass': 'पासवर्ड अपडेट करें',
      'statement_title': 'वित्तीय विवरण रिपोर्ट',
      'copy_report': 'रिपोर्ट कॉपी करें',
      'export_csv': 'CSV एक्सपोर्ट करें',
      'close': 'बंद करें',
      'breakdown_title': 'श्रेणी अनुसार खर्च विवरण व चार्ट',
      'limit_label': 'सीमा:',
      'select_lang': 'भाषा चुनें',
    }
  };

  static String tr(String key, {Map<String, String>? args}) {
    String res = dict[currentLang]?[key] ?? dict['en']?[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        res = res.replaceAll('{$k}', v);
      });
    }
    return res;
  }
}

class AuthScreen extends StatefulWidget {
  final bool isGoogleLogin;
  const AuthScreen({super.key, this.isGoogleLogin = false});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isGoogleLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _simulateGoogleLogin());
    }
  }

  Future<void> _simulateGoogleLogin() async {
    String googleEmail = "google_user_${math.Random().nextInt(9999)}@gmail.com";
    String googleName = "Google User";
    String sixDigitId = (100000 + math.Random().nextInt(900000)).toString();

    final docRef = FirebaseFirestore.instance.collection('users_data').doc(googleEmail);
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set({
        'name': googleName,
        'password': 'google_secure_pass',
        'sixDigitId': sixDigitId,
        'mobile': googleEmail,
        'avatar': null,
        'wallets': {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0},
        'goalTitle': 'Emergency Fund',
        'goalTarget': 50000.0,
        'customCategories': ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other'],
        'expenses': [],
        'subscriptions': [],
        'udhaar': [],
        'splits': [],
        'assets': [],
        'bills': [],
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_in_user', googleEmail);
    await prefs.setString('user_pass_$googleEmail', 'google_secure_pass');
    await prefs.setString('user_name_$googleEmail', googleName);
    await prefs.setString('user_six_id_$googleEmail', sixDigitId);

    UserDatabase.users[googleEmail] = {
      'name': googleName,
      'password': 'google_secure_pass',
      'sixDigitId': sixDigitId,
      'mobile': googleEmail,
      'avatar': null,
      'wallets': {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0},
      'goalTitle': 'Emergency Fund',
      'goalTarget': 50000.0,
      'customCategories': ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other'],
      'expenses': <ExpenseItem>[],
      'subscriptions': <SubscriptionItem>[],
      'udhaar': <UdhaarItem>[],
      'splits': <SplitGroup>[],
      'assets': <AssetItem>[],
      'bills': <BillItem>[],
    };

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(userEmail: googleEmail)));
  }

  void _showForgotPasswordDialog() {
    final recoveryIdCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    bool otpSent = false;
    String verifiedEmail = "";
    String generatedOtp = "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Forgot Password via OTP'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!otpSent) ...[
                  TextField(
                    controller: recoveryIdCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Enter 6-Digit Recovery ID or Mobile', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    onPressed: () async {
                      String rId = recoveryIdCtrl.text.trim();
                      if (rId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your ID or mobile!'), backgroundColor: Colors.red));
                        return;
                      }

                      final querySnap = await FirebaseFirestore.instance
                          .collection('users_data')
                          .where('sixDigitId', isEqualTo: rId)
                          .get();

                      if (querySnap.docs.isEmpty) {
                        final querySnap2 = await FirebaseFirestore.instance
                            .collection('users_data')
                            .where('mobile', isEqualTo: rId)
                            .get();
                        if (querySnap2.docs.isEmpty) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Account not found with this ID/Mobile!'), backgroundColor: Colors.red));
                          return;
                        } else {
                          verifiedEmail = querySnap2.docs.first.id;
                        }
                      } else {
                        verifiedEmail = querySnap.docs.first.id;
                      }

                      generatedOtp = (1000 + math.Random().nextInt(9000)).toString();
                      setDialogState(() {
                        otpSent = true;
                      });

                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('OTP sent successfully! (Demo OTP: $generatedOtp)'),
                          backgroundColor: Colors.green));
                    },
                    child: const Text('Send OTP'),
                  ),
                ] else ...[
                  Text('OTP sent for account: $verifiedEmail',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Enter 4-Digit OTP', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Retype New Password', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (otpCtrl.text.trim() != generatedOtp) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid OTP! Please try again.'), backgroundColor: Colors.red));
                        return;
                      }
                      if (newPassCtrl.text.trim().isEmpty ||
                          newPassCtrl.text.trim() != confirmPassCtrl.text.trim()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Passwords do not match or empty!'), backgroundColor: Colors.red));
                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('users_data')
                          .doc(verifiedEmail)
                          .update({'password': newPassCtrl.text.trim()});

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_pass_$verifiedEmail', newPassCtrl.text.trim());

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Password changed successfully via OTP!'), backgroundColor: Colors.green));
                    },
                    child: const Text('Verify & Change Password'),
                  ),
                ],
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
        ),
      ),
    );
  }

  Future<void> _submitAuthForm() async {
    final nameText = _nameController.text.trim();
    final idText = _identifierController.text.trim();
    final passwordText = _passwordController.text.trim();

    if (idText.isEmpty || passwordText.isEmpty || (!_isLogin && nameText.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields required!'), backgroundColor: Colors.redAccent));
      return;
    }

    if (!_isLogin) {
      final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
      final phoneRegex = RegExp(r"^[6-9]\d{9}$");
      if (!emailRegex.hasMatch(idText) && !phoneRegex.hasMatch(idText)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please enter valid 10-digit mobile number or email ID!'),
            backgroundColor: Colors.redAccent));
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();

    if (!_isLogin) {
      final docRef = FirebaseFirestore.instance.collection('users_data').doc(idText);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Already registered! Please login.'), backgroundColor: Colors.redAccent));
        return;
      }

      String sixDigitId = (100000 + math.Random().nextInt(900000)).toString();

      Map<String, dynamic> initialUserData = {
        'name': nameText,
        'password': passwordText,
        'sixDigitId': sixDigitId,
        'mobile': idText,
        'avatar': null,
        'wallets': {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0},
        'goalTitle': 'Emergency Fund',
        'goalTarget': 50000.0,
        'customCategories': ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other'],
        'expenses': [],
        'subscriptions': [],
        'udhaar': [],
        'splits': [],
        'assets': [],
        'bills': [],
      };

      await docRef.set(initialUserData);

      UserDatabase.users[idText] = {
        'name': nameText,
        'password': passwordText,
        'sixDigitId': sixDigitId,
        'mobile': idText,
        'avatar': null,
        'wallets': {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0},
        'goalTitle': 'Emergency Fund',
        'goalTarget': 50000.0,
        'customCategories': ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other'],
        'expenses': <ExpenseItem>[],
        'subscriptions': <SubscriptionItem>[],
        'udhaar': <UdhaarItem>[],
        'splits': <SplitGroup>[],
        'assets': <AssetItem>[],
        'bills': <BillItem>[],
      };

      await prefs.setString('user_pass_$idText', passwordText);
      await prefs.setString('user_name_$idText', nameText);
      await prefs.setString('user_six_id_$idText', sixDigitId);
      List<String> regUsers = prefs.getStringList('registered_users') ?? [];
      if (!regUsers.contains(idText)) {
        regUsers.add(idText);
        await prefs.setStringList('registered_users', regUsers);
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Account Created!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your 6-Digit Recovery ID is:'),
              Text(sixDigitId,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const Text('Note this down. Required if you forget password.',
                  style: TextStyle(fontSize: 11, color: Colors.grey))
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _isLogin = true;
                  _nameController.clear();
                  _passwordController.clear();
                });
              },
              child: const Text('Login'),
            )
          ],
        ),
      );
    } else {
      Map<String, dynamic>? userData;
      if (UserDatabase.users.containsKey(idText)) {
        userData = UserDatabase.users[idText];
      } else {
        final docSnap = await FirebaseFirestore.instance.collection('users_data').doc(idText).get();
        if (docSnap.exists) {
          final data = docSnap.data()!;
          userData = {
            'name': data['name'] ?? idText,
            'password': data['password'] ?? '123',
            'sixDigitId': data['sixDigitId'] ?? '123456',
            'mobile': idText,
            'avatar': data['avatar'],
            'wallets': data['wallets'] != null
                ? Map<String, double>.from(data['wallets'])
                : {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0},
            'goalTitle': data['goalTitle'] ?? 'Emergency Fund',
            'goalTarget': (data['goalTarget'] ?? 50000.0).toDouble(),
            'customCategories': data['customCategories'] != null
                ? List<String>.from(data['customCategories'])
                : ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other'],
            'expenses': (data['expenses'] as List? ?? []).map((e) => ExpenseItem.fromMap(e)).toList(),
            'subscriptions': (data['subscriptions'] as List? ?? []).map((e) => SubscriptionItem.fromMap(e)).toList(),
            'udhaar': (data['udhaar'] as List? ?? []).map((e) => UdhaarItem.fromMap(e)).toList(),
            'splits': (data['splits'] as List? ?? []).map((e) => SplitGroup.fromMap(e)).toList(),
            'assets': (data['assets'] as List? ?? []).map((e) => AssetItem.fromMap(e)).toList(),
            'bills': (data['bills'] as List? ?? []).map((e) => BillItem.fromMap(e)).toList(),
          };
          UserDatabase.users[idText] = userData;
        }
      }

      if (userData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID not found! Create account.'), backgroundColor: Colors.redAccent));
        return;
      }
      if (userData['password'] != passwordText) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect Password!'), backgroundColor: Colors.redAccent));
        return;
      }

      await prefs.setString('logged_in_user', idText);
      await prefs.setString('user_pass_$idText', passwordText);
      await prefs.setString('user_name_$idText', userData['name']);
      await prefs.setString('user_six_id_$idText', userData['sixDigitId']);
      if (userData['avatar'] != null) await prefs.setString('user_avatar_$idText', userData['avatar']);
      await prefs.setString('user_wallets_$idText', jsonEncode(userData['wallets']));
      await prefs.setString('user_goal_title_$idText', userData['goalTitle']);
      await prefs.setDouble('user_goal_target_$idText', userData['goalTarget']);
      await prefs.setStringList('user_categories_$idText', userData['customCategories']);
      await prefs.setString('user_expenses_$idText',
          jsonEncode((userData['expenses'] as List<ExpenseItem>).map((e) => e.toMap()).toList()));
      await prefs.setString('user_subs_$idText',
          jsonEncode((userData['subscriptions'] as List<SubscriptionItem>).map((e) => e.toMap()).toList()));
      await prefs.setString('user_udhaar_$idText',
          jsonEncode((userData['udhaar'] as List<UdhaarItem>).map((e) => e.toMap()).toList()));
      await prefs.setString('user_splits_$idText',
          jsonEncode((userData['splits'] as List<SplitGroup>).map((e) => e.toMap()).toList()));
      await prefs.setString('user_assets_$idText',
          jsonEncode((userData['assets'] as List<AssetItem>).map((e) => e.toMap()).toList()));
      await prefs.setString('user_bills_$idText',
          jsonEncode((userData['bills'] as List<BillItem>).map((e) => e.toMap()).toList()));

      List<String> regUsers = prefs.getStringList('registered_users') ?? [];
      if (!regUsers.contains(idText)) {
        regUsers.add(idText);
        await prefs.setStringList('registered_users', regUsers);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage(userEmail: idText)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F109E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen())),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF3F109E), Color(0xFF7A21D5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_rounded, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('DigitalHisab',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isLogin) ...[
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF7A21D5)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16)
                          ],
                          TextField(
                            controller: _identifierController,
                            decoration: InputDecoration(
                              labelText: 'Mobile / Email',
                              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7A21D5)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7A21D5)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00897B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _submitAuthForm,
                            child: Text(_isLogin ? 'Login' : 'Register',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text('Forgot Password?',
                                    style: TextStyle(color: Color(0xFF7A21D5), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? "Don't have an account? Create new" : 'Already have an account? Login',
                              style: const TextStyle(color: Color(0xFF7A21D5), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;
  final double total;
  _PieChartPainter({required this.categoryTotals, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) {
      canvas.drawCircle(size.center(Offset.zero), size.width / 3,
          Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 24);
      return;
    }
    final rect = Offset.zero & size;
    double startAngle = -math.pi / 2;
    final List<Color> colors = [
      const Color(0xFF9C27B0),
      const Color(0xFF4CAF50),
      const Color(0xFF3F51B5),
      const Color(0xFF00897B),
      const Color(0xFF5C6BC0),
      Colors.orange,
      Colors.teal,
      Colors.red
    ];
    int colorIndex = 0;

    categoryTotals.forEach((cat, val) {
      if (val > 0) {
        double sweepAngle = (val / total) * 2 * math.pi;
        final paint = Paint()
          ..color = colors[colorIndex % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect.deflate(24), startAngle, sweepAngle, false, paint);
        startAngle += sweepAngle;
        colorIndex++;
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HomePage extends StatefulWidget {
  final String userEmail;
  const HomePage({super.key, required this.userEmail});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Other';
  String _transactionType = 'Expense';
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterMonth = 'All';
  DateTime _selectedDate = DateTime.now();
  String _selectedWallet = 'UPI';

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_wallets_${widget.userEmail}', jsonEncode(_wallets));
    await prefs.setString('user_goal_title_${widget.userEmail}', _goalTitle);
    await prefs.setDouble('user_goal_target_${widget.userEmail}', _goalTarget);
    await prefs.setStringList('user_categories_${widget.userEmail}', _customCategories);

    await prefs.setString('user_expenses_${widget.userEmail}', jsonEncode(_expenses.map((e) => e.toMap()).toList()));
    await prefs.setString('user_subs_${widget.userEmail}', jsonEncode(_subscriptions.map((e) => e.toMap()).toList()));
    await prefs.setString('user_udhaar_${widget.userEmail}', jsonEncode(_udhaarList.map((e) => e.toMap()).toList()));
    await prefs.setString('user_splits_${widget.userEmail}', jsonEncode(_splitGroups.map((e) => e.toMap()).toList()));
    await prefs.setString('user_assets_${widget.userEmail}', jsonEncode(_assetsList.map((e) => e.toMap()).toList()));
    await prefs.setString('user_bills_${widget.userEmail}', jsonEncode(_bills.map((e) => e.toMap()).toList()));

    FirebaseFirestore.instance.collection('users_data').doc(widget.userEmail).set({
      'name': _userName,
      'password': UserDatabase.users[widget.userEmail]!['password'],
      'sixDigitId': _sixDigitId,
      'mobile': widget.userEmail,
      'avatar': UserDatabase.users[widget.userEmail]!['avatar'],
      'wallets': _wallets,
      'goalTitle': _goalTitle,
      'goalTarget': _goalTarget,
      'customCategories': _customCategories,
      'expenses': _expenses.map((e) => e.toMap()).toList(),
      'subscriptions': _subscriptions.map((e) => e.toMap()).toList(),
      'udhaar': _udhaarList.map((e) => e.toMap()).toList(),
      'splits': _splitGroups.map((e) => e.toMap()).toList(),
      'assets': _assetsList.map((e) => e.toMap()).toList(),
      'bills': _bills.map((e) => e.toMap()).toList(),
    }, SetOptions(merge: true)).catchError((e) => debugPrint(e.toString()));
  }

  List<ExpenseItem> get _expenses => UserDatabase.users[widget.userEmail]!['expenses'];
  List<SubscriptionItem> get _subscriptions => UserDatabase.users[widget.userEmail]!['subscriptions'];
  List<UdhaarItem> get _udhaarList => UserDatabase.users[widget.userEmail]!['udhaar'];
  List<SplitGroup> get _splitGroups => UserDatabase.users[widget.userEmail]!['splits'];
  List<AssetItem> get _assetsList => UserDatabase.users[widget.userEmail]!['assets'];
  List<BillItem> get _bills => UserDatabase.users[widget.userEmail]!['bills'];
  List<String> get _customCategories => UserDatabase.users[widget.userEmail]!['customCategories'];
  Map<String, double> get _wallets => UserDatabase.users[widget.userEmail]!['wallets'];

  String get _goalTitle => UserDatabase.users[widget.userEmail]!['goalTitle'] ?? 'Emergency Fund';
  set _goalTitle(String val) {
    UserDatabase.users[widget.userEmail]!['goalTitle'] = val;
    _saveUserData();
  }

  double get _goalTarget => UserDatabase.users[widget.userEmail]!['goalTarget'] ?? 50000.0;
  set _goalTarget(double val) {
    UserDatabase.users[widget.userEmail]!['goalTarget'] = val;
    _saveUserData();
  }

  String get _userName => UserDatabase.users[widget.userEmail]!['name'] as String;
  String get _sixDigitId => UserDatabase.users[widget.userEmail]!['sixDigitId'] ?? '------';

  double getWalletBalance(String walletName) {
    double bal = _wallets[walletName] ?? 0.0;
    for (var e in _expenses) {
      if (e.wallet == walletName) {
        if (e.type == 'Income') bal += e.amount;
        if (e.type == 'Expense') bal -= e.amount;
      }
    }
    return bal;
  }

  double get _totalBalance => getWalletBalance('Cash') + getWalletBalance('Bank') + getWalletBalance('UPI');
  double get _totalIncome =>
      _expenses.where((e) => e.type == 'Income').fold(0.0, (sum, item) => sum + item.amount);
  double get _thisMonthExpense =>
      _expenses.where((e) => e.type == 'Expense').fold(0.0, (sum, item) => sum + item.amount);
  double get _totalAssets => _assetsList.fold(0.0, (sum, item) => sum + item.assetValue);

  String _getTodayString() {
    DateTime now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}";
  }

  String _formatIndianCurrency(double amount) {
    String str = amount.toStringAsFixed(0);
    if (str.length > 3) {
      var lastThree = str.substring(str.length - 3);
      var otherNumbers = str.substring(0, str.length - 3);
      if (otherNumbers.isNotEmpty) {
        otherNumbers = otherNumbers.replaceAllMapped(RegExp(r'(\d{2})(?=\d{2})'), (match) => '${match[1]},');
      }
      return '$otherNumbers,$lastThree';
    }
    return str;
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image =
          await picker.pickImage(source: source, maxWidth: 400, maxHeight: 400, imageQuality: 75);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() => UserDatabase.users[widget.userEmail]!['avatar'] = base64String);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar_${widget.userEmail}', base64String);
        _saveUserData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF7A21D5)),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF7A21D5)),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              if (UserDatabase.users[widget.userEmail]!['avatar'] != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => UserDatabase.users[widget.userEmail]!['avatar'] = null);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('user_avatar_${widget.userEmail}');
                    _saveUserData();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocale.tr('select_lang'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: AppLocale.languages.entries.map((entry) {
                  bool isSelected = AppLocale.currentLang == entry.key;
                  return ListTile(
                    dense: true,
                    leading: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.deepPurple : Colors.grey),
                    title: Text(entry.value,
                        style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.deepPurple : Colors.black87)),
                    onTap: () {
                      GoluKaKharchApp.of(context)?.changeLanguage(entry.key);
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            onPressed: () async {
              String savedPass = UserDatabase.users[widget.userEmail]!['password'] ?? '123';
              if (currentPassCtrl.text.trim() == savedPass) {
                if (newPassCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    UserDatabase.users[widget.userEmail]!['password'] = newPassCtrl.text.trim();
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_pass_${widget.userEmail}', newPassCtrl.text.trim());
                  _saveUserData();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a new password!'), backgroundColor: Colors.red),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect current password!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  void _detectCategoryFromTitle(String text) {
    String q = text.toLowerCase().trim();
    if (q.contains('doodh') ||
        q.contains('milk') ||
        q.contains('chai') ||
        q.contains('tea') ||
        q.contains('khana') ||
        q.contains('food') ||
        q.contains('sabji') ||
        q.contains('rashan') ||
        q.contains('grocery') ||
        q.contains('swiggy') ||
        q.contains('zomato') ||
        q.contains('roti') ||
        q.contains('biscuit') ||
        q.contains('paneer') ||
        q.contains('maggi') ||
        q.contains('dudh') ||
        q.contains('bhaji') ||
        q.contains('kirana')) {
      if (_customCategories.contains('Grocery')) setState(() => _selectedCategory = 'Grocery');
    } else if (q.contains('bijli') ||
        q.contains('light') ||
        q.contains('bill') ||
        q.contains('water') ||
        q.contains('pani') ||
        q.contains('recharge') ||
        q.contains('wifi') ||
        q.contains('gas') ||
        q.contains('cylinder') ||
        q.contains('electricity') ||
        q.contains('current')) {
      if (_customCategories.contains('Utilities')) setState(() => _selectedCategory = 'Utilities');
    } else if (q.contains('rent') ||
        q.contains('kiraya') ||
        q.contains('room') ||
        q.contains('flat') ||
        q.contains('brokerage') ||
        q.contains('bhade') ||
        q.contains('ghar')) {
      if (_customCategories.contains('Rent')) setState(() => _selectedCategory = 'Rent');
    } else if (q.contains('salary') ||
        q.contains('tankhwah') ||
        q.contains('bonus') ||
        q.contains('profit') ||
        q.contains('freelance') ||
        q.contains('kamai') ||
        q.contains('cashback') ||
        q.contains('pagar') ||
        q.contains('pocket money')) {
      if (_customCategories.contains('Salary/Income')) {
        setState(() {
          _selectedCategory = 'Salary/Income';
          _transactionType = 'Income';
        });
      }
    }
  }

  void _showDueNotificationsDialog() {
    final dueTodayList =
        _udhaarList.where((u) => !u.isSettled && u.dueDate == _getTodayString()).toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Due Date Reminders'),
          ],
        ),
        content: dueTodayList.isEmpty
            ? const Text('Aaj koi due payment reminder nahi hai! 🎉', style: TextStyle(fontSize: 14))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dueTodayList.length,
                  itemBuilder: (c, index) {
                    final item = dueTodayList[index];
                    bool isGive = item.type == 'GIVE';
                    return ListTile(
                      dense: true,
                      leading: Icon(isGive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isGive ? Colors.green : Colors.red),
                      title: Text(item.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${isGive ? "Lena Hai" : "Dena Hai"}: ₹${_formatIndianCurrency(item.amount)}'),
                      trailing: Text(item.dueDate,
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _manageCategories() {
    final catCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Manage Custom Categories'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: catCtrl,
                        decoration: const InputDecoration(
                            hintText: 'New Category Name', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
                      onPressed: () {
                        if (catCtrl.text.isNotEmpty && !_customCategories.contains(catCtrl.text.trim())) {
                          setState(() {
                            _customCategories.add(catCtrl.text.trim());
                            _saveUserData();
                          });
                          setDialogState(() {});
                          catCtrl.clear();
                        }
                      },
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: _customCategories
                      .map((c) => Chip(
                            label: Text(c, style: const TextStyle(fontSize: 11)),
                            onDeleted: () {
                              setState(() {
                                _customCategories.remove(c);
                                _saveUserData();
                              });
                              setDialogState(() {});
                            },
                          ))
                      .toList(),
                )
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      ),
    );
  }

  void _openBackupRestore() {
    final restoreCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup & Restore Vault',
            style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Backup Your Data', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Apna poora data code mein convert karke copy kar lein.',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  String jsonData = jsonEncode(UserDatabase.users[widget.userEmail]);
                  String backupCode = base64Encode(utf8.encode(jsonData));
                  Clipboard.setData(ClipboardData(text: backupCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup Code Copied to Clipboard!'), backgroundColor: Colors.green));
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Backup Code'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
              const Divider(height: 30),
              const Text('Restore Data', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Naye phone mein wahi code yahan paste karein.',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: restoreCtrl,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Paste Backup Code Here', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  try {
                    String decodedJson = utf8.decode(base64Decode(restoreCtrl.text.trim()));
                    Map<String, dynamic> restoredData = jsonDecode(decodedJson);
                    setState(() {
                      UserDatabase.users[widget.userEmail]!['wallets'] = Map<String, double>.from(
                          restoredData['wallets'] ?? {'Cash': 100000.0, 'Bank': 0.0, 'UPI': 0.0});
                      UserDatabase.users[widget.userEmail]!['customCategories'] = List<String>.from(
                          restoredData['customCategories'] ??
                              ['Grocery', 'Utilities', 'Rent', 'Salary/Income', 'Other']);
                      UserDatabase.users[widget.userEmail]!['expenses'] = (restoredData['expenses'] as List? ?? [])
                          .map((e) => ExpenseItem.fromMap(e))
                          .toList();
                      UserDatabase.users[widget.userEmail]!['udhaar'] = (restoredData['udhaar'] as List? ?? [])
                          .map((e) => UdhaarItem.fromMap(e))
                          .toList();
                      UserDatabase.users[widget.userEmail]!['assets'] =
                          (restoredData['assets'] as List? ?? []).map((e) => AssetItem.fromMap(e)).toList();
                      UserDatabase.users[widget.userEmail]!['bills'] =
                          (restoredData['bills'] as List? ?? []).map((e) => BillItem.fromMap(e)).toList();
                      UserDatabase.users[widget.userEmail]!['subscriptions'] =
                          (restoredData['subscriptions'] as List? ?? [])
                              .map((e) => SubscriptionItem.fromMap(e))
                              .toList();
                      _saveUserData();
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data Restored Successfully!'), backgroundColor: Colors.green));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid Backup Code!'), backgroundColor: Colors.red));
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Restore Data'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _openSubscriptionManager() {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String billDay = "1";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.autorenew, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Active Subscriptions (Auto-Pay)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              ]),
              const Divider(),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Name (e.g. Netflix)', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), isDense: true),
                  ),
                )
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Billing Day: '),
                DropdownButton<String>(
                  value: billDay,
                  items: List.generate(
                    28,
                    (index) => DropdownMenuItem(value: "${index + 1}", child: Text("${index + 1} tarik")),
                  ),
                  onChanged: (val) => setModalState(() => billDay = val!),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty && amtCtrl.text.isNotEmpty) {
                      setState(() {
                        _subscriptions.add(SubscriptionItem(
                          id: DateTime.now().toString(),
                          title: titleCtrl.text.trim(),
                          amount: double.parse(amtCtrl.text.trim()),
                          billDate: billDay,
                        ));
                        _saveUserData();
                      });
                      titleCtrl.clear();
                      amtCtrl.clear();
                      setModalState(() {});
                    }
                  },
                  child: const Text('Add'),
                )
              ]),
              const Divider(),
              _subscriptions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No active subscriptions.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subscriptions.length,
                      itemBuilder: (c, i) {
                        final s = _subscriptions[i];
                        return ListTile(
                          leading: const Icon(Icons.play_circle_fill, color: Colors.red),
                          title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Har mahine ki ${s.billDate} tarik ko • ₹${s.amount}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _subscriptions.removeAt(i);
                                _saveUserData();
                              });
                              setModalState(() {});
                            },
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showManageWalletsDialog() {
    final cashCtrl = TextEditingController(text: getWalletBalance('Cash').toStringAsFixed(0));
    final bankCtrl = TextEditingController(text: getWalletBalance('Bank').toStringAsFixed(0));
    final upiCtrl = TextEditingController(text: getWalletBalance('UPI').toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Wallet Balances'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set current actual balance for each wallet:',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: cashCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cash (₹)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bankCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Bank (₹)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: upiCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'UPI (₹)', border: OutlineInputBorder(), isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B1BB6), foregroundColor: Colors.white),
            onPressed: () {
              double? nCash = double.tryParse(cashCtrl.text.trim());
              double? nBank = double.tryParse(bankCtrl.text.trim());
              double? nUpi = double.tryParse(upiCtrl.text.trim());
              setState(() {
                if (nCash != null) {
                  double eff = _expenses
                      .where((e) => e.wallet == 'Cash')
                      .fold(0.0, (s, e) => s + (e.type == 'Income' ? e.amount : -e.amount));
                  _wallets['Cash'] = nCash - eff;
                }
                if (nBank != null) {
                  double eff = _expenses
                      .where((e) => e.wallet == 'Bank')
                      .fold(0.0, (s, e) => s + (e.type == 'Income' ? e.amount : -e.amount));
                  _wallets['Bank'] = nBank - eff;
                }
                if (nUpi != null) {
                  double eff = _expenses
                      .where((e) => e.wallet == 'UPI')
                      .fold(0.0, (s, e) => s + (e.type == 'Income' ? e.amount : -e.amount));
                  _wallets['UPI'] = nUpi - eff;
                }
                _saveUserData();
              });
              Navigator.pop(context);
            },
            child: const Text('Update Balances'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Master Settings & Tools',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                  ],
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.autorenew, color: Colors.orange),
                  title: const Text('Subscriptions & Auto-Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Track Netflix, Gym, etc.'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _openSubscriptionManager();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category, color: Colors.blue),
                  title: const Text('Manage Custom Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Add your own expense types'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _manageCategories();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_sync, color: Colors.teal),
                  title: const Text('Data Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Keep your data safe'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _openBackupRestore();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language, color: Colors.deepPurple),
                  title: Text(AppLocale.tr('select_lang'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _showLanguageSelector();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_reset, color: Colors.purple),
                  title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Update your account password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _showChangePasswordDialog();
                  },
                ),
                const Divider(),
                const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete App Data & Account'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Account?'),
                          content: const Text('Are you sure? All transaction data will be erased.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.clear();
                                UserDatabase.users.remove(widget.userEmail);
                                await FirebaseFirestore.instance.collection('users_data').doc(widget.userEmail).delete();
                                if (!context.mounted) return;
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                    context, MaterialPageRoute(builder: (context) => const WelcomeScreen()));
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBillVault() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text('Bill & Warranty Vault',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add New Bill / Warranty'),
                    onPressed: () => _addNewBill(setModalState),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _bills.isEmpty
                        ? const Center(child: Text('No bills saved yet.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _bills.length,
                            itemBuilder: (ctx, i) {
                              final b = _bills[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: b.imageBase64.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => Dialog(
                                                child: InteractiveViewer(child: Image.memory(base64Decode(b.imageBase64))),
                                              ),
                                            );
                                          },
                                          child: Image.memory(base64Decode(b.imageBase64),
                                              width: 50, height: 50, fit: BoxFit.cover),
                                        )
                                      : const Icon(Icons.receipt),
                                  title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Bought: ${b.purchaseDate} \nWarranty Till: ${b.warrantyDate}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _bills.removeAt(i);
                                        _saveUserData();
                                      });
                                      setModalState(() {});
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
        },
      ),
    );
  }

  Future<void> _addNewBill(StateSetter setModalState) async {
    final tCtrl = TextEditingController();
    DateTime pDate = DateTime.now();
    DateTime wDate = DateTime.now().add(const Duration(days: 365));
    String? b64Image;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Save New Bill'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'Item Name (e.g. Fridge)')),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Purchase Date:'),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                              context: ctx, initialDate: pDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                          if (picked != null) setDialogState(() => pDate = picked);
                        },
                        child: Text('${pDate.day}.${pDate.month}.${pDate.year}'),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Warranty Till:'),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                              context: ctx, initialDate: wDate, firstDate: DateTime.now(), lastDate: DateTime(2040));
                          if (picked != null) setDialogState(() => wDate = picked);
                        },
                        child: Text('${wDate.day}.${wDate.month}.${wDate.year}'),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50, maxWidth: 800);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setDialogState(() => b64Image = base64Encode(bytes));
                      }
                    },
                    icon: const Icon(Icons.camera),
                    label: Text(b64Image == null ? 'Capture Bill Photo' : 'Photo Captured!'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (tCtrl.text.isNotEmpty && b64Image != null) {
                    setState(() {
                      _bills.insert(
                        0,
                        BillItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: tCtrl.text.trim(),
                          purchaseDate: "${pDate.day}.${pDate.month}.${pDate.year}",
                          warrantyDate: "${wDate.day}.${wDate.month}.${wDate.year}",
                          imageBase64: b64Image!,
                        ),
                      );
                      _saveUserData();
                    });
                    setModalState(() {});
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openUdhaarKhata() {
    final personController = TextEditingController();
    final amtController = TextEditingController();
    String udhaarType = 'GIVE';
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          double totalLenaHai =
              _udhaarList.where((u) => u.type == 'GIVE' && !u.isSettled).fold(0.0, (s, u) => s + u.amount);
          double totalDenaHai =
              _udhaarList.where((u) => u.type == 'TAKE' && !u.isSettled).fold(0.0, (s, u) => s + u.amount);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📒 ${AppLocale.tr('udhaar_title')}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocale.tr('lena_hai'),
                                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('₹${_formatIndianCurrency(totalLenaHai)}',
                                  style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold))
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocale.tr('dena_hai'),
                                  style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('₹${_formatIndianCurrency(totalDenaHai)}',
                                  style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold))
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(AppLocale.tr('new_udhaar'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(AppLocale.tr('gave_money')),
                        selected: udhaarType == 'GIVE',
                        selectedColor: Colors.green.shade100,
                        onSelected: (val) => setModalState(() => udhaarType = 'GIVE'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(AppLocale.tr('took_money')),
                        selected: udhaarType == 'TAKE',
                        selectedColor: Colors.red.shade100,
                        onSelected: (val) => setModalState(() => udhaarType = 'TAKE'),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: personController,
                          decoration: InputDecoration(
                              hintText: AppLocale.tr('person_name_hint'), border: const OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: amtController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              hintText: AppLocale.tr('amount_hint'), border: const OutlineInputBorder(), isDense: true),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Due Date: ${selectedDueDate.day}.${selectedDueDate.month}.${selectedDueDate.year}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Select Due Date'),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                              context: context, initialDate: selectedDueDate, firstDate: DateTime.now(), lastDate: DateTime(2035));
                          if (picked != null) setModalState(() => selectedDueDate = picked);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B1BB6), foregroundColor: Colors.white),
                      onPressed: () {
                        final amt = double.tryParse(amtController.text.trim());
                        if (personController.text.isNotEmpty && amt != null && amt > 0) {
                          String today = _getTodayString();
                          String formattedDueDate =
                              "${selectedDueDate.day.toString().padLeft(2, '0')}.${selectedDueDate.month.toString().padLeft(2, '0')}.${selectedDueDate.year}";
                          setState(() {
                            _udhaarList.insert(
                              0,
                              UdhaarItem(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                personName: personController.text.trim(),
                                amount: amt,
                                type: udhaarType,
                                date: today,
                                dueDate: formattedDueDate,
                              ),
                            );
                            _saveUserData();
                          });
                          personController.clear();
                          amtController.clear();
                          setModalState(() {});
                        }
                      },
                      child: Text(AppLocale.tr('save_udhaar')),
                    ),
                  ),
                  const Divider(),
                  Text(AppLocale.tr('past_dues'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _udhaarList.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(AppLocale.tr('no_dues'), style: const TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _udhaarList.length,
                          itemBuilder: (ctx, i) {
                            final u = _udhaarList[i];
                            bool isGive = u.type == 'GIVE';
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: u.isSettled
                                    ? Colors.grey.shade200
                                    : (isGive ? Colors.green.shade100 : Colors.red.shade100),
                                child: Icon(
                                  u.isSettled ? Icons.check : (isGive ? Icons.call_made : Icons.call_received),
                                  color: u.isSettled ? Colors.grey : (isGive ? Colors.green : Colors.red),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                u.personName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: u.isSettled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Text(
                                "${u.date} (Due: ${u.dueDate}) • ${isGive ? AppLocale.tr('lena_hai') : AppLocale.tr('dena_hai')} ${u.isSettled ? AppLocale.tr('settled_badge') : ''}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('₹${_formatIndianCurrency(u.amount)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, color: isGive ? Colors.green : Colors.red)),
                                  if (isGive && !u.isSettled) ...[
                                    IconButton(
                                      icon: const Icon(Icons.share, color: Colors.teal, size: 18),
                                      onPressed: () async {
                                        String msg =
                                            "Hello ${u.personName}, aapka ₹${u.amount} ka udhaar DigitalHisab ke anusar pending hai (Due Date: ${u.dueDate}). Kripya jald chuka dein!";
                                        await Share.share(msg);
                                      },
                                      tooltip: 'Share',
                                    )
                                  ],
                                  IconButton(
                                    icon: Icon(u.isSettled ? Icons.undo : Icons.check_circle_outline,
                                        color: u.isSettled ? Colors.grey : Colors.green),
                                    onPressed: () {
                                      setState(() {
                                        u.isSettled = !u.isSettled;
                                        _saveUserData();
                                      });
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openBillSplitter() {
    final groupNameCtrl = TextEditingController();
    final totalAmtCtrl = TextEditingController();
    final membersCtrl = TextEditingController(text: '2');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('👥 Smart Bill Splitter',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                  ],
                ),
                const Divider(),
                TextField(
                  controller: groupNameCtrl,
                  decoration: const InputDecoration(labelText: 'Group / Trip Name', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalAmtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Bill (₹)', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: membersCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Members Count', border: OutlineInputBorder(), isDense: true),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    onPressed: () {
                      String gName = groupNameCtrl.text.trim();
                      double? tAmt = double.tryParse(totalAmtCtrl.text.trim());
                      int? mCount = int.tryParse(membersCtrl.text.trim());
                      if (gName.isNotEmpty && tAmt != null && tAmt > 0 && mCount != null && mCount > 0) {
                        setState(() {
                          _splitGroups.insert(
                            0,
                            SplitGroup(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              groupName: gName,
                              totalAmount: tAmt,
                              membersCount: mCount,
                            ),
                          );
                          _saveUserData();
                        });
                        groupNameCtrl.clear();
                        totalAmtCtrl.clear();
                        setModalState(() {});
                      }
                    },
                    child: const Text('Calculate & Save Split'),
                  ),
                ),
                const Divider(),
                const Text('Saved Group Splits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _splitGroups.isEmpty
                    ? const Padding(padding: EdgeInsets.all(10), child: Text('No split records yet.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _splitGroups.length,
                        itemBuilder: (ctx, i) {
                          final s = _splitGroups[i];
                          double perPerson = s.totalAmount / s.membersCount;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                                backgroundColor: Colors.purple, child: Icon(Icons.group, color: Colors.white, size: 18)),
                            title: Text(s.groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Total: ₹${s.totalAmount} • Members: ${s.membersCount}'),
                            trailing: Text('₹${perPerson.toStringAsFixed(1)} / person',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          );
                        },
                      ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAssetTracker() {
    final assetNameCtrl = TextEditingController();
    final assetValCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('💎 Net Worth Tracker',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                  ],
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Net Worth:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('₹${_formatIndianCurrency(_totalBalance + _totalAssets)}',
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w900, fontSize: 16))
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: assetNameCtrl,
                  decoration: const InputDecoration(labelText: 'Asset Name', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: assetValCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Asset Value (₹)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    onPressed: () {
                      String aName = assetNameCtrl.text.trim();
                      double? aVal = double.tryParse(assetValCtrl.text.trim());
                      if (aName.isNotEmpty && aVal != null && aVal >= 0) {
                        setState(() {
                          _assetsList.insert(
                            0,
                            AssetItem(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              assetName: aName,
                              assetValue: aVal,
                            ),
                          );
                          _saveUserData();
                        });
                        assetNameCtrl.clear();
                        assetValCtrl.clear();
                        setModalState(() {});
                      }
                    },
                    child: const Text('Add Asset'),
                  ),
                ),
                const Divider(),
                const Text('Your Asset Portfolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                _assetsList.isEmpty
                    ? const Padding(padding: EdgeInsets.all(10), child: Text('No assets added yet.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _assetsList.length,
                        itemBuilder: (ctx, i) {
                          final a = _assetsList[i];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 18)),
                            title: Text(a.assetName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Text('₹${_formatIndianCurrency(a.assetValue)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          );
                        },
                      ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editSavingsGoal() {
    final titleCtrl = TextEditingController(text: _goalTitle);
    final targetCtrl = TextEditingController(text: _goalTarget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🐷 ${AppLocale.tr('goal_title_prefix')}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target (₹)'),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(targetCtrl.text.trim());
              if (titleCtrl.text.isNotEmpty && amt != null && amt > 0) {
                setState(() {
                  _goalTitle = titleCtrl.text.trim();
                  _goalTarget = amt;
                  _saveUserData();
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DIGITALHISAB STATEMENT',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                  pw.Text(_getTodayString(), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700))
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Account Name: $_userName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  pw.Text('User ID: $_sixDigitId', style: const pw.TextStyle(fontSize: 12)),
                  pw.Divider(color: PdfColors.grey300),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Net Balance: Rs. ${_formatIndianCurrency(_totalBalance)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Net Worth: Rs. ${_formatIndianCurrency(_totalBalance + _totalAssets)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal))
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Income: Rs. ${_formatIndianCurrency(_totalIncome)}',
                          style: const pw.TextStyle(color: PdfColors.green)),
                      pw.Text('Total Expense: Rs. ${_formatIndianCurrency(_thisMonthExpense)}',
                          style: const pw.TextStyle(color: PdfColors.red))
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Transaction History', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Date', 'Type', 'Title', 'Wallet', 'Amount'],
              data: _expenses.map((e) => [e.date, e.type, e.title, e.wallet, 'Rs. ${e.amount}']).toList(),
            ),
          ];
        },
      ),
    );
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(), name: 'DigitalHisab_Report_$_sixDigitId.pdf');
  }

  void _generateStatement() {
    String report =
        "=== DIGITALHISAB PRO STATEMENT ===\nUser: $_userName (ID: $_sixDigitId)\nNet Balance: ₹${_formatIndianCurrency(_totalBalance)}\nTotal Assets (Net Worth): ₹${_formatIndianCurrency(_totalBalance + _totalAssets)}\nTotal Income: ₹${_formatIndianCurrency(_totalIncome)}\nMonth Expense: ₹${_formatIndianCurrency(_thisMonthExpense)}\n\nDate | Type | Title | Wallet | Amount\n---------------------------------------\n";
    for (var e in _expenses) {
      report += "${e.date} | ${e.type} | ${e.title} | ${e.wallet} | ₹${e.amount}\n";
    }
    String csvReport = "Date,Type,Title,Wallet,Category,Amount\n";
    for (var e in _expenses) {
      csvReport += "${e.date},${e.type},\"${e.title}\",${e.wallet},${e.category},${e.amount}\n";
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Financial Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(report, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF Download'),
            onPressed: () async {
              Navigator.pop(context);
              await _generatePdfReport();
            },
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.deepPurple),
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvReport));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('CSV Copied!'), backgroundColor: Colors.teal));
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Report Copied!'), backgroundColor: Colors.green));
              Navigator.pop(context);
            },
            child: const Text('Copy Report'),
          ),
        ],
      ),
    );
  }

  void _showSpendingGraph() {
    Map<String, double> categoryTotals = {};
    for (var c in _customCategories) {
      categoryTotals[c] = 0.0;
    }
    for (var e in _expenses) {
      if (e.type == 'Expense') {
        categoryTotals[e.category] = (categoryTotals[e.category] ?? 0.0) + e.amount;
      }
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Spending Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _PieChartPainter(categoryTotals: categoryTotals, total: _thisMonthExpense),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Total Expense', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text('₹${_formatIndianCurrency(_thisMonthExpense)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              ...categoryTotals.entries.map((entry) {
                double percentage = _thisMonthExpense > 0 ? (entry.value / _thisMonthExpense) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${_formatIndianCurrency(entry.value)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12))
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.deepPurple,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
        context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  void _addNewExpense() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) return;

    String formattedDate =
        "${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}";
    String formattedTime =
        "${TimeOfDay.now().hourOfPeriod}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} ${TimeOfDay.now().period == DayPeriod.am ? 'AM' : 'PM'}";

    setState(() {
      _expenses.insert(
        0,
        ExpenseItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          amount: amount,
          type: _transactionType,
          date: formattedDate,
          time: formattedTime,
          category: _selectedCategory,
          wallet: _selectedWallet,
        ),
      );
      _saveUserData();
    });
    _titleController.clear();
    _amountController.clear();
    FocusScope.of(context).unfocus();
  }

  Widget _buildWalletMiniCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String amount,
    required Color coinColor,
    required bool isAddable,
    VoidCallback? onAddPressed,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              Row(
                children: [
                  if (isAddable) ...[
                    InkWell(onTap: onAddPressed, child: const Icon(Icons.edit, color: Color(0xFF00897B), size: 20)),
                    const SizedBox(width: 6)
                  ],
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: coinColor,
                    child: const Text('₹',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(amount,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    List<String> availableMonths = ['All'];
    for (var e in _expenses) {
      List<String> parts = e.date.split('.');
      if (parts.length == 3) {
        String mYear = "${parts[1]}.${parts[2]}";
        if (!availableMonths.contains(mYear)) availableMonths.add(mYear);
      }
    }

    List<ExpenseItem> filteredExpenses = _expenses.where((item) {
      bool matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesCat = _filterCategory == 'All' || item.category == _filterCategory;
      bool matchesMonth = _filterMonth == 'All' || item.date.endsWith(_filterMonth);
      return matchesSearch && matchesCat && matchesMonth;
    }).toList();

    double piggySavings = _totalBalance > 0 ? _totalBalance : 0.0;
    double goalPercent = (_goalTarget > 0) ? (piggySavings / _goalTarget).clamp(0.0, 1.0) : 0.0;
    String? userAvatarBase64 = UserDatabase.users[widget.userEmail]?['avatar'];
    int pendingDueCount =
        _udhaarList.where((u) => !u.isSettled && u.dueDate == _getTodayString()).length;

    if (!_customCategories.contains(_selectedCategory)) {
      _selectedCategory = _customCategories.isNotEmpty ? _customCategories.first : 'Other';
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF3F109E), Color(0xFF7A21D5)]),
              ),
              currentAccountPicture: GestureDetector(
                onTap: _showImagePickerOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          userAvatarBase64 != null ? MemoryImage(base64Decode(userAvatarBase64)) : null,
                      child: userAvatarBase64 == null
                          ? const Icon(Icons.person, color: Colors.white, size: 32)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: const Color(0xFF00897B),
                        child: const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: Text('ID: $_sixDigitId', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF7A21D5)),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.orange),
              title: const Text('Notifications & Due Reminders'),
              trailing: pendingDueCount > 0
                  ? CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text('$pendingDueCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _showDueNotificationsDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blue),
              title: const Text('Master Settings'),
              onTap: () {
                Navigator.pop(context);
                _openSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.teal),
              title: const Text('Financial Reports'),
              onTap: () {
                Navigator.pop(context);
                _generateStatement();
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.indigo),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share App'),
              onTap: () {
                Navigator.pop(context);
                Share.share("Manage your daily expenses easily with DigitalHisab!");
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('logged_in_user');
                if (!context.mounted) return;
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const WelcomeScreen()));
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedFintechHeader(
                  height: 310,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.white24,
                                          backgroundImage: userAvatarBase64 != null
                                              ? MemoryImage(base64Decode(userAvatarBase64))
                                              : null,
                                          child: userAvatarBase64 == null
                                              ? const Icon(Icons.person, color: Colors.white, size: 20)
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: CircleAvatar(
                                            radius: 6,
                                            backgroundColor: const Color(0xFF00897B),
                                            child: const Icon(Icons.menu, size: 8, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 90),
                                          child: Text(
                                            'Hi, $_userName',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        Text('ID: $_sixDigitId',
                                            style: const TextStyle(
                                                color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                          icon: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                                          onPressed: _openBillVault,
                                          tooltip: 'Bill & Warranty Vault',
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                          icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                                          onPressed: _openUdhaarKhata,
                                          tooltip: AppLocale.tr('udhaar_title'),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                          icon: const Icon(Icons.group_work, color: Colors.white, size: 20),
                                          onPressed: _openBillSplitter,
                                          tooltip: 'Smart Bill Splitter',
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                          icon: const Icon(Icons.account_balance_wallet,
                                              color: Colors.white, size: 20),
                                          onPressed: _openAssetTracker,
                                          tooltip: 'Net Worth Assets',
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                          icon: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
                                          onPressed: _showSpendingGraph,
                                          tooltip: 'Spending Breakdown',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 52,
                          width: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.4),
                                      blurRadius: 18,
                                      spreadRadius: 3,
                                    )
                                  ],
                                ),
                              ),
                              const Icon(Icons.account_balance, size: 44, color: Color(0xFFFFD700)),
                              const Positioned(
                                  top: 15, child: Icon(Icons.currency_rupee, size: 17, color: Color(0xFF280654))),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.verified, size: 16, color: Color(0xFF00E676)),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('$_userName | DigitalHisab',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))
                                ])),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 210,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBalanceCard(
                          title: AppLocale.tr('net_balance'),
                          amount: '₹ ${_formatIndianCurrency(_totalBalance)}',
                          coinColor: const Color(0xFFD4AF37),
                          isAddable: true,
                          onAddPressed: _showManageWalletsDialog,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBalanceCard(
                          title: AppLocale.tr('month_expense'),
                          amount: '₹ ${_formatIndianCurrency(_thisMonthExpense)}',
                          coinColor: const Color(0xFFC0C0C0),
                          isAddable: false,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                      child: _buildWalletMiniCard(
                          'CASH', '₹ ${_formatIndianCurrency(getWalletBalance('Cash'))}', Icons.payments, Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildWalletMiniCard('BANK',
                          '₹ ${_formatIndianCurrency(getWalletBalance('Bank'))}', Icons.account_balance, Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildWalletMiniCard('UPI',
                          '₹ ${_formatIndianCurrency(getWalletBalance('UPI'))}', Icons.qr_code, Colors.purple)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🐷', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text('${AppLocale.tr('goal_title_prefix')} $_goalTitle',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: _editSavingsGoal,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: goalPercent,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF00897B),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${AppLocale.tr('savings_label')} ₹${_formatIndianCurrency(piggySavings)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        '${AppLocale.tr('target_label')} ₹${_formatIndianCurrency(_goalTarget)} (${(goalPercent * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(AppLocale.tr('expense')),
                        selected: _transactionType == 'Expense',
                        onSelected: (val) => setState(() => _transactionType = 'Expense'),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: Text(AppLocale.tr('income')),
                        selected: _transactionType == 'Income',
                        onSelected: (val) => setState(() => _transactionType = 'Income'),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocale.tr('title_note_label'),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.grey.shade800,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(10)),
                              child: TextField(
                                controller: _titleController,
                                onChanged: _detectCategoryFromTitle,
                                decoration: InputDecoration(
                                  hintText: AppLocale.tr('title_hint'),
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  suffixIcon: const Icon(Icons.auto_awesome, size: 18, color: Colors.deepPurple),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocale.tr('amount_label'),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.grey.shade800,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(10)),
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'Amount',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(top: 12, left: 12),
                                    child: Text('₹', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: $_selectedCategory',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.grey.shade800,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(10)),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _customCategories
                                      .map((c) => Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 3),
                                            child: ChoiceChip(
                                              label: Text(c,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: _selectedCategory == c
                                                          ? Colors.white
                                                          : (isDark ? Colors.white70 : Colors.black87))),
                                              selected: _selectedCategory == c,
                                              selectedColor: Colors.deepPurple,
                                              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                              onSelected: (val) => setState(() => _selectedCategory = c),
                                              visualDensity: VisualDensity.compact,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocale.tr('date_label'),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.grey.shade800,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Center(
                                    child: Icon(Icons.calendar_today_outlined, size: 20, color: Colors.deepPurple)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('Paid via:',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey.shade800,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Cash', style: TextStyle(fontSize: 11)),
                        selected: _selectedWallet == 'Cash',
                        onSelected: (v) => setState(() => _selectedWallet = 'Cash'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Bank', style: TextStyle(fontSize: 11)),
                        selected: _selectedWallet == 'Bank',
                        onSelected: (v) => setState(() => _selectedWallet = 'Bank'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('UPI', style: TextStyle(fontSize: 11)),
                        selected: _selectedWallet == 'UPI',
                        onSelected: (v) => setState(() => _selectedWallet = 'UPI'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _addNewExpense,
                      child: Text(AppLocale.tr('add_tx_btn'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: AppLocale.tr('search_hint'),
                          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _filterCategory,
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      underline: const SizedBox(),
                      items: ['All', ..._customCategories].map<DropdownMenuItem<String>>((String c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _filterCategory = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _filterMonth,
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      underline: const SizedBox(),
                      items: availableMonths.map<DropdownMenuItem<String>>((String m) {
                        return DropdownMenuItem<String>(
                          value: m,
                          child: Text(m, style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _filterMonth = val!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(AppLocale.tr('recent_title'),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ),
            ),
            const SizedBox(height: 12),
            filteredExpenses.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(AppLocale.tr('no_tx_found'), style: const TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (ctx, i) {
                      final item = filteredExpenses.isEmpty ? null : filteredExpenses[i];
                      if (item == null) return const SizedBox.shrink();
                      bool isIncome = item.type == 'Income';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.category, color: Colors.deepPurple, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${item.category} • via ${item.wallet} • ${item.date} ${item.time}",
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                  )
                                ],
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}₹${_formatIndianCurrency(item.amount)}',
                              style: TextStyle(
                                  color: isIncome ? Colors.green : (isDark ? Colors.white : Colors.black87),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}