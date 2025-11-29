import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// ⭐️ مكتبة FCM الجديدة
import 'package:firebase_messaging/firebase_messaging.dart';

// ⭐️ استيراد صفحة الإعدادات والتقارير
import 'settings_page.dart';
import 'reports_page.dart';
import 'subscription_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Controllers
  final _manualTitleController = TextEditingController();
  final _manualAmountController = TextEditingController();
  final _manualNotesController = TextEditingController();
  final _budgetController = TextEditingController();

  final _recorder = FlutterSoundRecorder();
  bool _isRecording = false;

  List<Map<String, dynamic>> _allExpenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];

  // Animations
  late AnimationController _animationController;
  late AnimationController _rotateAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  // Recording State
  String? _audioPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // User Status State
  bool _isPro = false;
  int _recordingCount = 0;

  // UI State
  bool _showSwipeHint = true;
  bool _isLoading = true;
  double _monthlyBudget = 0.0;
  bool _isBalanceCardExpanded = false;
  bool _showExtraDetails = false;

  // Filter Variables
  String _selectedCurrency = 'EGP';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  List<String> _selectedCategoriesFilter = [];
  List<DateTime> _monthList = [];

  // Currencies
  final Map<String, String> _currencies = {
    'EGP': '🇪🇬', 'USD': '🇺🇸', 'SAR': '🇸🇦', 'EUR': '🇪🇺', 'AED': '🇦🇪',
    'KWD': '🇰🇼', 'GBP': '🇬🇧', 'JPY': '🇯🇵', 'CAD': '🇨🇦', 'AUD': '🇦🇺',
    'CHF': '🇨🇭', 'CNY': '🇨🇳', 'INR': '🇮🇳', 'TRY': '🇹🇷', 'QAR': '🇶🇦',
  };

  CancelToken? _cancelToken;
  StreamSubscription? _authSubscription;
  final Dio _dio = Dio();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // ⭐️ قائمة الفئات
  List<Map<String, dynamic>> _categories = [
    {'name': 'طعام وشراب', 'icon': Icons.fastfood_rounded, 'color': Colors.orange},
    {'name': 'مواصلات', 'icon': Icons.directions_car_rounded, 'color': Colors.blue},
    {'name': 'تسوق', 'icon': Icons.shopping_bag_rounded, 'color': Colors.purple},
    {'name': 'ترفيه', 'icon': Icons.sports_esports_rounded, 'color': Colors.pink},
    {'name': 'فواتير', 'icon': Icons.receipt_long_rounded, 'color': Colors.red},
    {'name': 'صحة', 'icon': Icons.local_hospital_rounded, 'color': Colors.green},
    {'name': 'تعليم', 'icon': Icons.school_rounded, 'color': Colors.indigo},
    {'name': 'سفر ورحلات', 'icon': Icons.flight_takeoff_rounded, 'color': Colors.teal},
    {'name': 'عمل', 'icon': Icons.work_rounded, 'color': Colors.brown},
    {'name': 'البيت', 'icon': Icons.home_rounded, 'color': Colors.cyan},
    {'name': 'هدايا', 'icon': Icons.card_giftcard_rounded, 'color': Colors.yellow},
    {'name': 'أخرى', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
  ];

  String _selectedCategory = 'أخرى';

  static const String OPENAI_API_KEY = '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';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('en', null);
    tz.initializeTimeZones();
    _initializeRecorder();
    _initializeNotifications();
    _loadSwipeHintPreference();
    _loadCurrency();
    _loadBudget();
    _generateMonthList();
    _loadCustomCategories();

    // 🔥 إعداد الإشعارات السحابية (FCM)
    _setupFirebaseMessaging();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotateAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 360.0).animate(
      CurvedAnimation(parent: _rotateAnimationController, curve: Curves.linear),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
      _checkFirstTimeCurrency();
    });

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _fetchExpenses();
        _fetchUserStatus();
      } else {
        setState(() {
          _allExpenses = [];
          _filterExpenses();
          _isLoading = false;
        });
      }
    });
  }

  // ⭐️ إعداد FCM وطلب الإذن وتحديث التوكن
  Future<void> _setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // طلب الإذن (مهم للأندرويد 13+ والآيفون)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('FCM Permission granted');

      // الحصول على التوكن
      String? token = await messaging.getToken();
      print("FCM Token: $token");

      // إرسال التوكن للسيرفر
      if (token != null) {
        _updateServerToken(token);
      }

      // الاستماع لتحديث التوكن تلقائياً
      messaging.onTokenRefresh.listen((newToken) {
        _updateServerToken(newToken);
      });

      // الاستماع للرسائل والتطبيق مفتوح (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        if (message.notification != null) {
          _showSnackBar('🔔 ${message.notification!.title}: ${message.notification!.body}', Colors.blue);
        }
      });
    }
  }

  // ⭐️ دالة إرسال التوكن للسيرفر
  Future<void> _updateServerToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _dio.post(
        'https://mk-app.com/api-app/update_fcm_token.php',
        data: {
          'uid': user.uid,
          'fcm_token': token,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      print("FCM Token updated on server successfully");
    } catch (e) {
      print("Failed to update FCM token: $e");
    }
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('custom_categories');
    if (savedData != null) {
      List<dynamic> decoded = jsonDecode(savedData);
      setState(() {
        for (var item in decoded) {
          bool exists = _categories.any((cat) => cat['name'] == item['name']);
          if (!exists) {
            _categories.add({
              'name': item['name'],
              'icon': IconData(item['icon'], fontFamily: 'MaterialIcons'),
              'color': Colors.blueGrey,
            });
          }
        }
      });
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _initializeApp() async {
    if (!await _checkConnectivity()) {
      _showNoInternetDialog();
      return;
    }
    if (!mounted) return;
    bool shouldProceed = await _checkAppStatus();
    if (shouldProceed) {
      _fetchExpenses();
      _fetchUserStatus();
    }
  }

  Future<void> _fetchUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await _dio.get(
        'https://mk-app.com/api-app/get_user_status.php',
        queryParameters: {'uid': user.uid},
      );

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          var data = response.data;
          int isProVal = (data['is_pro'] is int) ? data['is_pro'] : int.tryParse(data['is_pro'].toString()) ?? 0;
          _isPro = (isProVal == 1);

          int countVal = (data['recording_count'] is int) ? data['recording_count'] : int.tryParse(data['recording_count'].toString()) ?? 0;
          _recordingCount = countVal;
        });

        if (response.data['subscription_expired'] == true) {
          _showExpirationDialog();
        }
      }
    } catch (e) {
      print('Error fetching user status: $e');
    }
  }

  Future<void> _incrementRecordingOnServer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _dio.post(
        'https://mk-app.com/api-app/increment_recording.php',
        data: {'uid': user.uid},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      setState(() {
        _recordingCount++;
      });
    } catch (e) {
      print('Error incrementing recording: $e');
    }
  }

  // --- Popups & Dialogs ---
  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 50),
        title: const Text('ترقية للنسخة الاحترافية', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'هذه الميزة متاحة فقط للمشتركين. اشترك الآن للحصول على تسجيلات غير محدودة وإضافة يدوية مفتوحة وتقارير شاملة!',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // إغلاق النافذة المنبثقة

              // ⭐️ الانتقال إلى صفحة الاشتراك
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionPage()),
              ).then((_) {
                // تحديث حالة المستخدم (Pro/Free) عند العودة من صفحة الدفع
                _fetchUserStatus();
              });
            },
            child: const Text('اشترك الآن'),
          ),
        ],
      ),
    );
  }

  void _showExpirationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.timer_off_rounded, color: Colors.red, size: 50),
        title: const Text('انتهت صلاحية الاشتراك', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'للأسف، انتهت فترة اشتراكك البرو. تم تحويل حسابك للخطة المجانية.\n\nيرجى تجديد الاشتراك للاستمرار في التمتع بالمميزات الكاملة.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('لاحقاً', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showUpgradeDialog();
            },
            child: const Text('تجديد الآن'),
          ),
        ],
      ),
    );
  }

  void _showNoInternetDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Icon(Icons.signal_wifi_off_rounded, color: Colors.red.shade700, size: 48),
            title: const Text("انقطاع الاتصال", style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
              "يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _initializeApp();
                },
                child: const Text('إعادة المحاولة', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencySelectionDialog() {
    String? tempSelectedCurrency = _selectedCurrency;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('اختر عملتك الأساسية'),
              content: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.4,
                child: ListView(
                  shrinkWrap: true,
                  children: _currencies.keys.map((String key) {
                    return RadioListTile<String>(
                      title: Text('${_currencies[key]!} $key'),
                      value: key,
                      groupValue: tempSelectedCurrency,
                      onChanged: (String? value) {
                        setDialogState(() {
                          tempSelectedCurrency = value;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('حفظ واختيار'),
                  onPressed: () {
                    if (tempSelectedCurrency != null) {
                      _saveCurrency(tempSelectedCurrency!);
                      setState(() {
                        _selectedCurrency = tempSelectedCurrency!;
                      });
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("الرجاء اختيار عملة"))
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _checkAppStatus() async {
    try {
      final response = await _dio.get(
        'https://mk-app.com/api-app/app_status.php',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['maintenance_mode'] == true) {
          _showMaintenanceDialog(data['maintenance_title'], data['maintenance_message']);
          return false;
        }
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;
        String latestVersion = data['latest_version'];
        if (data['force_update'] == true && _isNewerVersion(latestVersion, currentVersion)) {
          _showForceUpdateDialog(data['update_title'], data['update_message'], data['update_url']);
          return false;
        }
        if (data['show_message'] == true) {
          final prefs = await SharedPreferences.getInstance();
          final String messageId = data['message_id'];
          final String seenMessageId = prefs.getString('seen_message_id') ?? '';
          if (messageId != seenMessageId) {
            _showGeneralMessageDialog(data['message_title'], data['message_message'], messageId);
          }
        }
        if (data['show_action_message'] == true) {
          final prefs = await SharedPreferences.getInstance();
          final String actionId = data['action_message_id'];
          final String seenActionId = prefs.getString('seen_action_id') ?? '';
          if (actionId != seenActionId) {
            _showActionMessageDialog(
                data['action_title'],
                data['action_body'],
                data['action_btn_text'],
                data['action_url'],
                actionId
            );
          }
        }
        return true;
      }
    } catch (e) {
      print("خطأ في فحص حالة التطبيق: $e");
    }
    return true;
  }

  bool _isNewerVersion(String newVersion, String oldVersion) {
    return newVersion != oldVersion;
  }

  void _showMaintenanceDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Icon(Icons.build_circle, color: Colors.orange.shade700, size: 48),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  void _showForceUpdateDialog(String title, String message, String updateUrl) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Icon(Icons.system_update_alt, color: Colors.blue.shade700, size: 48),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () async {
                  final Uri url = Uri.parse(updateUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('تحديث الآن', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGeneralMessageDialog(String title, String message, String messageId) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.info_outline, color: Colors.blue.shade700, size: 48),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('seen_message_id', messageId);
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('إغلاق', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showActionMessageDialog(String title, String body, String btnText, String urlStr, String actionId) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.campaign_rounded, color: Colors.purple.shade600, size: 48),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            body,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('seen_action_id', actionId);
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('seen_action_id', actionId);
                if (mounted) Navigator.of(context).pop();

                final Uri url = Uri.parse(urlStr);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(btnText),
            ),
          ],
        );
      },
    );
  }

  // --- Budget & Currency Logic ---
  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('selectedCurrency') ?? 'EGP';
    });
  }

  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCurrency', currency);
    await prefs.setBool('hasSelectedCurrency', true);
  }

  void _checkFirstTimeCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSelected = prefs.getBool('hasSelectedCurrency') ?? false;
    if (!hasSelected && mounted) {
      if (ModalRoute.of(context)?.isCurrent != true) return;
      _showCurrencySelectionDialog();
    }
  }

  String _getBudgetKey() {
    final monthFormat = DateFormat('yyyy-MM');
    return 'budget_${monthFormat.format(_selectedMonth)}';
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    String budgetKey = _getBudgetKey();
    setState(() {
      _monthlyBudget = prefs.getDouble(budgetKey) ?? 0.0;
    });
  }

  Future<void> _saveBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    String budgetKey = _getBudgetKey();
    await prefs.setDouble(budgetKey, budget);
  }

  void _generateMonthList() {
    _monthList = [];
    final now = DateTime.now();
    for (int i = 12; i > 0; i--) {
      _monthList.add(DateTime(now.year, now.month - i, 1));
    }
    for (int i = 0; i < 12; i++) {
      _monthList.add(DateTime(now.year, now.month + i, 1));
    }
  }

  String _getDynamicExpenseDate() {
    final int currentDay = DateTime.now().day;
    final int selectedYear = _selectedMonth.year;
    final int selectedMonth = _selectedMonth.month;
    final int daysInSelectedMonth = DateUtils.getDaysInMonth(selectedYear, selectedMonth);
    final int validDay = (currentDay > daysInSelectedMonth) ? daysInSelectedMonth : currentDay;
    final DateTime expenseDate = DateTime(selectedYear, selectedMonth, validDay);
    return DateFormat('yyyy-MM-dd').format(expenseDate);
  }

  Future<void> _loadSwipeHintPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showSwipeHint = prefs.getBool('showSwipeHintExpense') ?? true;
    });
    if (_showSwipeHint) {
      prefs.setBool('showSwipeHintExpense', false);
    }
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 10));
  }

  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _showProcessingDialog() {
    _rotateAnimationController.repeat();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnimation.value * 3.14159 / 180,
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.blue.shade600,
                        size: 48,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'جاري المعالجة ...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيتم الإضافة في لحظات',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideProcessingDialog() {
    _rotateAnimationController.stop();
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  // ⭐️ منطق التسجيل المعدل
  Future<void> _toggleRecording() async {
    // 1. التحقق من الليمت للمستخدم المجاني
    if (!_isRecording && !_isPro && _recordingCount >= 5) {
      _showUpgradeDialog();
      return;
    }

    if (!_isRecording) {
      bool hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        _showSnackBar('مطلوب إذن الميكروفون لتسجيل الصوت', Colors.red.shade400);
        return;
      }

      final directory = await getTemporaryDirectory();
      _audioPath = '${directory.path}/expense_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.startRecorder(
        toFile: _audioPath,
        codec: Codec.aacMP4,
        bitRate: 128000,
        sampleRate: 44100,
      );

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      HapticFeedback.lightImpact();

      // 2. ضبط التايمر بناءً على الخطة (10 مجاني / 30 برو)
      int maxDuration = _isPro ? 30 : 10;

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });

        if (_recordingSeconds >= maxDuration) {
          _toggleRecording();
          _showSnackBar(
              _isPro ? 'الحد الأقصى للتسجيل 30 ثانية' : 'الحد الأقصى 10 ثواني (نسخة مجانية)',
              Colors.orange
          );
        }
      });
    } else {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      _recordingTimer?.cancel();
      _recordingTimer = null;
      HapticFeedback.lightImpact();

      if (_audioPath != null) {
        final audioFile = File(_audioPath!);
        if (await audioFile.exists() && await audioFile.length() > 100) {
          _showProcessingDialog();
          await _processAudioFile(audioFile);
          _hideProcessingDialog();
        } else {
          _showSnackBar('التسجيل قصير جدًا أو فشل في إنشاء الملف', Colors.orange.shade400);
        }
      }
    }
  }

  Future<void> _processAudioFile(File audioFile) async {
    try {
      final fileSize = await audioFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('حجم الملف كبير جدًا');
      }

      if (!await _checkConnectivity()) {
        _showNoInternetDialog();
        return;
      }

      _cancelToken = CancelToken();
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioFile.path, filename: 'audio.m4a'),
        'model': 'whisper-1',
        'language': 'ar',
        'response_format': 'verbose_json',
        'temperature': '0.2',
        'prompt': 'مصروف، دفعت، اشتريت، اتصرف، فلوس، جنيه، ريال، دولار, دخل, ايراد, جالي فلوس, راتب, أكل, سفر, مواصلات, تسوق, ترفيه, فواتير, صحة, تعليم, هدايا, بيت, عمل',
      });

      final response = await _dio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $OPENAI_API_KEY'},
        ),
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String transcribedText = data['text'] ?? '';
        if (transcribedText.isNotEmpty) {
          await _processVoiceCommand(transcribedText);
        } else {
          throw Exception('لم يتم التعرف على أي نص من التسجيل');
        }
      } else {
        throw Exception('فشل في تحويل الصوت إلى نص: ${response.data}');
      }
    } catch (e) {
      _showSnackBar('خطأ في معالجة الصوت: $e', Colors.red.shade400);
    } finally {
      if (_audioPath != null) {
        try {
          final file = File(_audioPath!);
          if (await file.exists()) await file.delete();
        } catch (e) {
          print('خطأ في حذف الملف المؤقت: $e');
        }
      }
    }
  }

  Future<void> _processVoiceCommand(String text) async {
    try {
      if (!await _checkConnectivity()) {
        _showNoInternetDialog();
        return;
      }

      final formattedDate = _getDynamicExpenseDate();

      // ⭐️ تجميع أسماء الفئات لإرسالها في الـ Prompt
      String categoriesString = _categories.map((e) => e['name']).join('، ');

      _cancelToken = CancelToken();
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': '''
أنت مساعد مالي ذكي، ومهمتك هي تحليل **اللغة العامية المصرية** واستخراج **كل** المعاملات المالية المذكورة.
- يجب أن ترجع **قائمة (array) JSON** تحتوي على كل المعاملات.
- إذا لم تجد أي معاملات، أرجع قائمة فارغة [].
- حدد نوع المعاملة: 'income' (للدخل مثل: جالي، راتب، إيراد) أو 'expense' (للمصروفات مثل: صرفت، دفعت، اشتريت).
- الفئات المتاحة: $categoriesString. 
- التاريخ الحالي لكل المعاملات هو: $formattedDate

مثال 1: "جالي 5000 من شغلي وصرفت 300 أكل"
الرد يجب أن يكون (JSON Array فقط):
[
  { "amount": 5000, "type": "income", "category": "عمل", "notes": "من شغلي" },
  { "amount": 300, "type": "expense", "category": "طعام وشراب", "notes": "أكل" }
]

مثال 2: "دفعت 100 جنيه مواصلات"
الرد يجب أن يكون (JSON Array فقط):
[
  { "amount": 100, "type": "expense", "category": "مواصلات", "notes": null }
]
'''
            },
            {'role': 'user', 'content': text}
          ],
          'max_tokens': 1000,
          'temperature': 0.0,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $OPENAI_API_KEY'},
        ),
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices'][0]['message']['content'];

        final RegExp jsonRegex = RegExp(r'\[[\s\S]*\]');
        final Match? match = jsonRegex.firstMatch(content);

        if (match == null) {
          throw Exception('فشل الذكاء الاصطناعي في إرجاع قائمة JSON صالحة. الرد: $content');
        }

        final String cleanedContent = match.group(0)!;
        final List<dynamic> expenseList = jsonDecode(cleanedContent);

        if (expenseList.isEmpty) {
          _showSnackBar('لم يتم التعرف على أي معاملات في التسجيل', Colors.orange.shade400);
          return;
        }

        int successCount = 0;
        for (var item in expenseList) {
          final Map<String, dynamic> expenseData = item as Map<String, dynamic>;

          final expense = {
            'amount': expenseData['amount']?.toString() ?? '0',
            'type': expenseData['type'] ?? 'expense',
            'category': expenseData['category'] ?? 'أخرى',
            'notes': expenseData['notes'],
            'date': formattedDate,
            'userId': FirebaseAuth.instance.currentUser?.uid,
          };

          final savedExpense = await _saveExpense(expense);
          if (savedExpense != null) {
            successCount++;
          }
        }

        if (successCount > 0) {
          _showSnackBar('تم إضافة $successCount معاملة (معاملات) بنجاح ✓', Colors.blue.shade400);
          await _fetchExpenses();

          // ⭐️ زيادة العداد في السيرفر إذا لم يكن برو
          if (!_isPro) {
            await _incrementRecordingOnServer();
          }
        }

      } else {
        throw Exception('فشل في معالجة الأمر الصوتي');
      }
    } catch (e) {
      _showSnackBar('خطأ في معالجة الأمر: $e', Colors.red.shade400);
    }
  }

  Future<Map<String, dynamic>?> _saveExpense(Map<String, dynamic> expense) async {
    try {
      if (!await _checkConnectivity()) {
        _showNoInternetDialog();
        return null;
      }

      Response response;
      bool isEditing = expense.containsKey('id') && expense['id'] != null;

      if (isEditing) {
        response = await _dio.put(
          'https://mk-app.com/api-app/expenses.php',
          data: jsonEncode(expense),
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
      } else {
        response = await _dio.post(
          'https://mk-app.com/api-app/expenses.php',
          data: jsonEncode(expense),
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!isEditing && (response.data is Map) && response.data['id'] != null) {
          expense['id'] = response.data['id'];
        }
        return expense;
      } else {
        throw Exception('فشل في حفظ المصروف');
      }
    } catch (e) {
      _showSnackBar('خطأ في حفظ المصروف: $e', Colors.orange.shade400);
      return null;
    }
  }

  Future<void> _fetchExpenses() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _allExpenses = [];
        _filterExpenses();
      });
      return;
    }

    try {
      _cancelToken = CancelToken();
      final response = await _dio.get(
        'https://mk-app.com/api-app/expenses.php?userId=$userId',
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<Map<String, dynamic>> fetchedExpenses = [];

        if (data is List) {
          fetchedExpenses = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['expenses'] != null) {
          fetchedExpenses = List<Map<String, dynamic>>.from(data['expenses']);
        }

        setState(() {
          _allExpenses = fetchedExpenses;
          _filterExpenses();
        });

        _checkBudgetNotifications();

      }
    } catch (e) {
      _showSnackBar('فشل في جلب المصاريف: $e', Colors.red.shade400);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterExpenses() {
    List<Map<String, dynamic>> tempExpenses = [];

    final String currentMonthFormat = DateFormat('yyyy-MM').format(_selectedMonth);
    tempExpenses = _allExpenses.where((expense) {
      final expenseDateStr = expense['date'];
      if (expenseDateStr == null) return false;
      return expenseDateStr.startsWith(currentMonthFormat);
    }).toList();

    if (_selectedCategoriesFilter.isNotEmpty) {
      tempExpenses = tempExpenses.where((expense) {
        return _selectedCategoriesFilter.contains(expense['category']);
      }).toList();
    }

    setState(() {
      _filteredExpenses = tempExpenses;
    });
  }

  Future<void> _deleteExpenseFromServer(Map<String, dynamic> expense) async {
    try {
      if (!await _checkConnectivity()) {
        _showNoInternetDialog();
        return;
      }

      if (expense['id'] == null) return;

      await _dio.delete(
        'https://mk-app.com/api-app/expenses.php',
        data: jsonEncode({
          'id': expense['id'],
          'userId': expense['userId'],
        }),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } catch (e) {
      print('خطأ في حذف المصروف: $e');
    }
  }

  Future<void> _sendBudgetNotification(String percentageLabel, double totalExpenses, double budget) async {
    final String title = 'تنبيه الميزانية';
    final String body =
        'لقد تجاوزت $percentageLabel من ميزانيتك. مصاريفك: ${totalExpenses.toStringAsFixed(0)} من ${budget.toStringAsFixed(0)} $_selectedCurrency';

    final androidDetails = AndroidNotificationDetails(
      'budget_channel',
      'Budget Notifications',
      channelDescription: 'Notifications for budget thresholds',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'تنبيه ميزانية',
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> _checkBudgetNotifications() async {
    final double totalExpenses = _calculateTotalFilteredExpenses();
    final double budget = _monthlyBudget;

    if (budget <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String monthKey = DateFormat('yyyy-MM').format(_selectedMonth);
    final double percentage = (totalExpenses / budget);

    final thresholds = {
      1.0: '100%',
      0.75: '75%',
      0.5: '50%',
      0.25: '25%'
    };

    for (final entry in thresholds.entries) {
      final double threshold = entry.key;
      final String label = entry.value;
      final String prefKey = 'notified_${label}_$monthKey';

      if (percentage >= threshold) {
        final bool alreadyNotified = prefs.getBool(prefKey) ?? false;

        if (!alreadyNotified) {
          print('إرسال إشعار: $label');
          await _sendBudgetNotification(label, totalExpenses, budget);
          await prefs.setBool(prefKey, true);
        }
      }
    }
  }

  void _showSetBudgetDialog() {
    _budgetController.text = _monthlyBudget > 0 ? _monthlyBudget.toStringAsFixed(0) : '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تحديد ميزانية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'كم تريد أن تنفق هذا الشهر؟',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'الميزانية',
                  hintText: '0',
                  prefixText: '$_selectedCurrency ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.attach_money, color: Colors.blue[700]),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'المبلغ مطلوب';
                  }
                  if (double.tryParse(value) == null) {
                    return 'أدخل مبلغ صحيح';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_budgetController.text) ?? 0.0;
                await _saveBudget(amount);
                setState(() {
                  _monthlyBudget = amount;
                });

                _checkBudgetNotifications();

                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showManualAddDialog({Map<String, dynamic>? expenseToEdit}) {
    // ⭐️ التحقق من الخطة المجانية (إذا لم يكن تعديل)
    if (expenseToEdit == null && !_isPro) {
      _showUpgradeDialog();
      return;
    }

    final _formKey = GlobalKey<FormState>();
    bool isEditing = expenseToEdit != null;

    String selectedType = 'expense';

    if (isEditing) {
      _manualAmountController.text = expenseToEdit['amount']?.toString() ?? '';
      _manualNotesController.text = expenseToEdit['notes'] ?? '';
      _selectedCategory = expenseToEdit['category'] ?? 'أخرى';
      selectedType = expenseToEdit['type'] ?? 'expense';
    } else {
      _manualAmountController.clear();
      _manualNotesController.clear();
      _selectedCategory = 'أخرى';
      selectedType = 'expense';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.add_card, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(isEditing ? 'تعديل المعاملة' : 'إضافة معاملة'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'expense',
                            label: Text('مصروف'),
                            icon: Icon(Icons.arrow_upward_rounded),
                          ),
                          ButtonSegment<String>(
                            value: 'income',
                            label: Text('دخل'),
                            icon: Icon(Icons.arrow_downward_rounded),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setDialogState(() {
                            selectedType = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: selectedType == 'expense'
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          selectedForegroundColor: selectedType == 'expense'
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                          foregroundColor: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _manualAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'المبلغ',
                          hintText: 'أدخل المبلغ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'المبلغ مطلوب';
                          }
                          if (double.tryParse(value) == null) {
                            return 'أدخل مبلغ صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'الفئة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['name'],
                            child: Row(
                              children: [
                                Icon(cat['icon'], color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(cat['name']),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _manualNotesController,
                        decoration: InputDecoration(
                          labelText: 'ملاحظات (اختياري)',
                          hintText: 'أضف أي ملاحظات',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      _showProcessingDialog();

                      final newExpense = {
                        'amount': _manualAmountController.text,
                        'type': selectedType,
                        'category': _selectedCategory,
                        'notes': _manualNotesController.text.isNotEmpty
                            ? _manualNotesController.text
                            : null,
                        'date': isEditing ? expenseToEdit['date'] : _getDynamicExpenseDate(),
                        'userId': FirebaseAuth.instance.currentUser?.uid,
                        if (isEditing) 'id': expenseToEdit['id'],
                      };

                      final savedExpense = await _saveExpense(newExpense);
                      _hideProcessingDialog();

                      if (savedExpense != null) {
                        await _fetchExpenses();
                        _showSnackBar(
                            isEditing
                                ? 'تم تعديل المعاملة ✓'
                                : 'تمت إضافة المعاملة بنجاح ✓',
                            Colors.blue.shade400);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteExpense(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف المعاملة'),
        content: const Text('هل أنت متأكد من حذف هذه المعاملة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _allExpenses.removeWhere((item) => item['id'] == expense['id']);
                _filterExpenses();
              });

              _checkBudgetNotifications();

              await _deleteExpenseFromServer(expense);
              _showSnackBar('تم حذف المعاملة ✓', Colors.blue.shade400);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  double _calculateTotalFilteredExpenses() {
    return _filteredExpenses
        .where((exp) => exp['type'] == 'expense')
        .fold(0.0, (sum, exp) => sum + (double.tryParse(exp['amount']?.toString() ?? '0') ?? 0.0));
  }

  double _calculateTotalFilteredIncome() {
    return _filteredExpenses
        .where((exp) => exp['type'] == 'income')
        .fold(0.0, (sum, exp) => sum + (double.tryParse(exp['amount']?.toString() ?? '0') ?? 0.0));
  }

  @override
  void dispose() {
    _manualTitleController.dispose();
    _manualAmountController.dispose();
    _manualNotesController.dispose();
    _budgetController.dispose();
    _animationController.dispose();
    _rotateAnimationController.dispose();
    if (_recorder.isRecording) {
      _recorder.stopRecorder();
    }
    _recorder.closeRecorder();
    _recordingTimer?.cancel();
    _cancelToken?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor();
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildIdleMicButton() {
    return FloatingActionButton(
      onPressed: _toggleRecording,
      backgroundColor: Colors.blue.shade700,
      elevation: 8.0,
      tooltip: 'بدء التسجيل',
      child: const Icon(Icons.mic, color: Colors.white, size: 30),
    );
  }

  Widget _buildRecordingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_formatTimer(_recordingSeconds)} / ${_isPro ? "0:30" : "0:10"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.graphic_eq, color: Colors.white, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _toggleRecording,
          backgroundColor: Colors.red.shade600,
          elevation: 8.0,
          tooltip: 'إيقاف التسجيل',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.stop, color: Colors.white, size: 30),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double totalExpenses, double totalIncome) {
    final netBalance = totalIncome - totalExpenses;
    final netBalanceColor = netBalance >= 0 ? Colors.green[700] : Colors.red[600];

    double percentage = 0.0;
    if (_monthlyBudget > 0) {
      percentage = totalExpenses / _monthlyBudget;
    }

    double barPercentage = percentage.clamp(0.0, 1.0);
    final progressColor = percentage > 1.0 ? Colors.red[600] : Colors.blue[700];

    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الرصيد الصافي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          '${netBalance.toStringAsFixed(2)} $_selectedCurrency',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: netBalanceColor,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isBalanceCardExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isBalanceCardExpanded = !_isBalanceCardExpanded;
                          if (!_isBalanceCardExpanded) {
                            _showExtraDetails = false;
                          }
                        });
                      },
                    )
                  ],
                ),
                if (_isBalanceCardExpanded)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showExtraDetails = !_showExtraDetails;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showExtraDetails ? 'إخفاء التفاصيل' : 'عرض المزيد من التفاصيل',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                            Icon(
                              _showExtraDetails ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              color: Colors.blue[700],
                            )
                          ],
                        ),
                      ),

                      if(_showExtraDetails)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('إجمالي الدخل:', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                                Text(
                                  '${totalIncome.toStringAsFixed(2)} $_selectedCurrency',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('إجمالي المصروفات:', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                                Text(
                                  '${totalExpenses.toStringAsFixed(2)} $_selectedCurrency',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[600]),
                                ),
                              ],
                            ),
                          ],
                        ),

                      const Divider(height: 12),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'ميزانية المصروفات',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            child: Text(
                              _monthlyBudget > 0 ? 'تعديل' : 'تحديد ميزانية',
                              style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: _showSetBudgetDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: 20,
                            width: (MediaQuery.of(context).size.width - 64) * barPercentage,
                            decoration: BoxDecoration(
                              color: progressColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                '${(percentage * 100).toStringAsFixed(0)}% تم صرفه',
                                style: TextStyle(
                                  color: barPercentage > 0.5 ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final ScrollController scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final index = _monthList.indexWhere((month) =>
        month.year == _selectedMonth.year && month.month == _selectedMonth.month);
        if (index != -1) {
          final position = index * 100.0;
          scrollController.jumpTo(position - (MediaQuery.of(context).size.width / 2) + 50);
        }
      }
    });

    return Container(
      height: 60,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _monthList.length,
        itemBuilder: (context, index) {
          final month = _monthList[index];
          final bool isSelected = month.year == _selectedMonth.year && month.month == _selectedMonth.month;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: GestureDetector(
              onTap: () async {
                setState(() {
                  _selectedMonth = month;
                });
                await _loadBudget();
                _filterExpenses();

                _checkBudgetNotifications();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 90,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade700 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 4)
                    )
                  ] : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.MMM('en').format(month),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      DateFormat.y('en').format(month),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    return IconButton(
      icon: Icon(
        Icons.filter_list_rounded,
        color: Colors.grey[600],
        size: 28,
      ),
      onPressed: _showFilterDialog,
    );
  }

  Widget _buildAddManualButton() {
    return TextButton.icon(
      icon: Icon(Icons.add_circle_outline, color: Colors.blue[700]),
      label: Text(
        'إضافة يدوي',
        style: TextStyle(
          color: Colors.blue[700],
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => _showManualAddDialog(),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('فلترة حسب الفئة'),
              content: Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final categoryName = category['name'];
                    final isSelected = _selectedCategoriesFilter.contains(categoryName);

                    return CheckboxListTile(
                      title: Text(categoryName),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedCategoriesFilter.add(categoryName);
                          } else {
                            _selectedCategoriesFilter.remove(categoryName);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('مسح الكل'),
                  onPressed: () {
                    setDialogState(() {
                      _selectedCategoriesFilter.clear();
                    });
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('تطبيق'),
                  onPressed: () {
                    _filterExpenses();
                    _checkBudgetNotifications();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUserHeaderInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. العملة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCurrency,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                isDense: true,
                items: _currencies.keys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Row(
                      children: [
                        Text(_currencies[key]!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCurrency = newValue!;
                  });
                  _saveCurrency(newValue!);
                },
              ),
            ),
          ),

          // 2. حالة الخطة (مجاني / برو)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isPro ? Colors.amber.shade100 : Colors.blue.shade100, // تغيير اللون للذهبي إذا برو
              borderRadius: BorderRadius.circular(12),
              border: _isPro ? Border.all(color: Colors.amber.shade700, width: 1.5) : null,
            ),
            child: Row(
              children: [
                if (_isPro) const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                if (_isPro) const SizedBox(width: 4),
                Text(
                  _isPro ? 'PRO' : 'خطة مجانية',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isPro ? Colors.amber.shade900 : Colors.blue,
                      fontSize: 14
                  ),
                ),
              ],
            ),
          ),

          // 3. عداد التسجيلات (مايكروفون)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: _isPro ? Colors.amber.shade50 : Colors.white, // خلفية ذهبية خفيفة للبرو
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isPro ? Colors.amber : Colors.grey.shade300)
            ),
            child: Row(
              children: [
                Icon(Icons.mic, size: 20, color: _isPro ? Colors.amber.shade800 : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _isPro ? '∞' : '$_recordingCount / 5',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _isPro ? Colors.amber.shade900 : Colors.black87
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'مرحبًا';
    final totalExpenses = _calculateTotalFilteredExpenses();
    final totalIncome = _calculateTotalFilteredIncome();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          userName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [

          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.bar_chart_rounded, size: 28, color: Colors.grey.shade600),
              tooltip: 'التقارير',
              onPressed: () {
                // 👇 التحقق إذا كان برو أم لا
                if (!_isPro) {
                  _showUpgradeDialog();
                } else {
                  // الانتقال إلى صفحة التقارير الحقيقية
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportsPage()),
                  );
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.alarm_add_rounded, size: 28, color: Colors.grey.shade600),
              tooltip: 'إضافة تذكير',
              onPressed: () {
                Navigator.pushNamed(context, '/add_reminder');
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              // ⭐️ تعديل الأيقونة لتفتح الإعدادات
              icon: Icon(
                Icons.settings_outlined,
                size: 28,
                color: Colors.grey.shade600,
              ),
              onPressed: () async {
                // الانتقال لصفحة الإعدادات وانتظار العودة لتحديث الفئات
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
                // إعادة تحميل الفئات المخصصة بعد العودة
                _loadCustomCategories();
              },
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.grey.shade100,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeaderInfo(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _buildSummaryCard(totalExpenses, totalIncome),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'المعاملات',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        _buildFilterButton(),
                        const SizedBox(width: 8),
                        _buildAddManualButton(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMonthSelector(),
                    const SizedBox(height: 12),

                    if (_showSwipeHint && _filteredExpenses.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.swipe_left, size: 22, color: Colors.blue.shade600),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'اضغط أو اسحب لليسار للتعديل أو الحذف',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredExpenses.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                        onRefresh: _fetchExpenses,
                        child: ListView.builder(
                          itemCount: _filteredExpenses.length,
                          itemBuilder: (context, index) {
                            return _buildExpenseItem(_filteredExpenses[index]);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isRecording
          ? _buildRecordingControls()
          : _buildIdleMicButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _selectedCategoriesFilter.isEmpty
                ? 'لا توجد معاملات لهذا الشهر'
                : 'لا توجد نتائج للفلتر المحدد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'ابدأ بإضافة معاملة جديدة باستخدام التسجيل الصوتي أو الإضافة اليدوية',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    // البحث عن الفئة بالاسم
    final cat = _categories.firstWhere(
          (c) => c['name'] == category,
      orElse: () => _categories.last, // إذا لم توجد، استخدم "أخرى"
    );

    // إذا كانت الأيقونة مخزنة كـ int (للفئات المخصصة)
    if (cat['icon'] is int) {
      return IconData(cat['icon'], fontFamily: 'MaterialIcons');
    }
    // إذا كانت IconData (للفئات الافتراضية)
    return cat['icon'];
  }

  Widget _buildExpenseItem(Map<String, dynamic> expense) {
    final itemKey = Key(expense['id']?.toString() ?? expense.hashCode.toString());
    final amount = double.tryParse(expense['amount']?.toString() ?? '0') ?? 0.0;
    final category = expense['category'] ?? 'أخرى';
    final isIncome = expense['type'] == 'income';

    final amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade600;
    final amountIcon = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final categoryIconColor = isIncome ? Colors.green.shade700 : Colors.blue.shade700;

    return Slidable(
      key: itemKey,
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        dismissible: null,
        extentRatio: 0.4,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Slidable.of(context)?.close();
                          _showManualAddDialog(expenseToEdit: expense);
                        },
                        child: Container(
                          color: Colors.blue.shade600,
                          height: double.infinity,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit, color: Colors.white, size: 24),
                              SizedBox(height: 4),
                              Text('تعديل', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Slidable.of(context)?.close();
                          _deleteExpense(expense);
                        },
                        child: Container(
                          color: Colors.red.shade600,
                          height: double.infinity,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, color: Colors.white, size: 24),
                              SizedBox(height: 4),
                              Text('حذف', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Slidable.of(context)?.openEndActionPane();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categoryIconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: categoryIconColor,
                size: 24,
              ),
            ),
            title: Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                expense['date'] ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  amountIcon,
                  color: amountColor,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${amount.toStringAsFixed(2)} $_selectedCurrency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
