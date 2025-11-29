import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

// استيراد صفحة الإعدادات للربط
import 'settings_page.dart';
import 'subscription_page.dart';

class AddReminderPage extends StatefulWidget {
  const AddReminderPage({super.key});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> with TickerProviderStateMixin {
  // Controllers
  final _manualTitleController = TextEditingController();
  final _manualDetailsController = TextEditingController();
  final _manualAmountController = TextEditingController();

  final _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  List<Map<String, dynamic>> _reminders = [];

  // Animations
  late AnimationController _animationController;
  late AnimationController _rotateAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  // Recording State
  String? _audioPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // User Status
  bool _isPro = false;
  int _recordingCount = 0;

  // UI State
  bool _showSwipeHint = true;
  bool _isLoading = true;
  String _selectedCategory = 'أخرى';

  // ⭐️ متغير العملة (افتراضي EGP حتى يتم التحميل)
  String _selectedCurrency = 'EGP';

  // Networking
  CancelToken? _cancelToken;
  StreamSubscription? _authSubscription;
  final Dio _dio = Dio();

  // Notifications
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // قائمة الفئات (قابلة للتعديل الآن)
  List<Map<String, dynamic>> _categories = [
    {'name': 'طعام وشراب', 'icon': Icons.fastfood_rounded},
    {'name': 'مواصلات', 'icon': Icons.directions_car_rounded},
    {'name': 'تسوق', 'icon': Icons.shopping_bag_rounded},
    {'name': 'ترفيه', 'icon': Icons.sports_esports_rounded},
    {'name': 'فواتير', 'icon': Icons.receipt_long_rounded},
    {'name': 'صحة', 'icon': Icons.local_hospital_rounded},
    {'name': 'تعليم', 'icon': Icons.school_rounded},
    {'name': 'سفر ورحلات', 'icon': Icons.flight_takeoff_rounded},
    {'name': 'عمل', 'icon': Icons.work_rounded},
    {'name': 'البيت', 'icon': Icons.home_rounded},
    {'name': 'هدايا', 'icon': Icons.card_giftcard_rounded},
    {'name': 'أخرى', 'icon': Icons.more_horiz_rounded},
  ];

  static const String OPENAI_API_KEY = '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';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('en', null);
    _initializeNotifications();
    _initializeRecorder();
    _loadSwipeHintPreference();
    _loadCustomCategories();
    _loadCurrency(); // ⭐️ تحميل العملة عند البدء

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

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _fetchReminders();
        _fetchUserStatus();
      } else {
        setState(() {
          _reminders = [];
          _isLoading = false;
        });
      }
    });
  }

  // ⭐️ دالة تحميل العملة
  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('selectedCurrency') ?? 'EGP';
    });
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
            });
          }
        }
      });
    }
  }

  Future<void> _loadSwipeHintPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showSwipeHint = prefs.getBool('showSwipeHintReminders') ?? true;
    });
    if (_showSwipeHint) {
      prefs.setBool('showSwipeHintReminders', false);
    }
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
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
                        Icons.mic,
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

  Future<void> _toggleRecording() async {
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
      _audioPath = '${directory.path}/reminder_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
        throw Exception('لا يوجد اتصال بالإنترنت');
      }

      _cancelToken = CancelToken();
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioFile.path, filename: 'audio.m4a'),
        'model': 'whisper-1',
        'language': 'ar',
        'response_format': 'verbose_json',
        'temperature': '0.2',
        'prompt': 'تذكير، فكرني، اجتماع، دوا، علاج، موعد، دفع، فاتورة، فلوس، جنيه, مصروف, دخل',
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
        throw Exception('فشل في تحويل الصوت إلى نص (${response.statusCode})');
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
        throw Exception('لا يوجد اتصال بالإنترنت');
      }

      final now = DateTime.now();
      final localTimeZone = tz.getLocation('Africa/Cairo');
      final localTime = tz.TZDateTime.now(localTimeZone);
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);

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
أنت مساعد ذكي لإنشاء تذكيرات مالية باللغة العامية. مهمتك استخراج **المعاملات المالية** و**توقيتاتها**.
- يجب أن ترجع **قائمة (array) JSON** تحتوي على كل التذكيرات.
- التاريخ الحالي: $formattedDate، والوقت: ${localTime.hour}:${localTime.minute}.
- استخرج `title` (العنوان)، `date` (YYYY-MM-DD)، `time` (HH:MM)، `amount` (الرقم فقط)، `type` ('expense' أو 'income')، و `category`.
- الفئات المتاحة: $categoriesString.
- إذا ذكر المستخدم "الشهر الجاي" أو "الشهر اللي جاي"، احسب التاريخ بناءً على الشهر التالي.
- ⭐️ **(قاعدة مهمة) إذا لم يحدد المستخدم وقتاً (ساعة) بشكل صريح، استخدم '12:00' (12 ظهراً) كوقت افتراضي. لا تترك الوقت 'null' أبداً.**

مثال 1: "فكرني أدفع 500 جنيه فاتورة النت يوم 10 الشهر الجاي"
الرد:
[
  { "title": "دفع فاتورة النت", "date": "${DateFormat('yyyy-MM').format(DateTime(now.year, now.month + 1, 1))}-10", "time": "12:00", "amount": 500, "type": "expense", "category": "فواتير" }
]

مثال 2: "تذكير بكرة الصبح عندي اجتماع شغل مهم وجالي 1000 جنيه"
الرد:
[
  { "title": "اجتماع شغل مهم", "date": "${DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 1)))}", "time": "09:00", "amount": 0, "type": "expense", "category": "عمل" },
  { "title": "جالي 1000 جنيه", "date": "$formattedDate", "time": "${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}", "amount": 1000, "type": "income", "category": "عمل" }
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
        final List<dynamic> remindersData = jsonDecode(cleanedContent);

        if (remindersData.isNotEmpty) {
          int successCount = 0;
          for (var reminderData in remindersData) {
            final reminder = {
              'title': reminderData['title'] ?? 'تذكير عام',
              'details': reminderData['notes'],
              'date': reminderData['date'] ?? formattedDate,
              'time': reminderData['time'],
              'amount': reminderData['amount'] ?? 0.0,
              'type': reminderData['type'] ?? 'expense',
              'category': reminderData['category'] ?? 'أخرى',
              'userId': FirebaseAuth.instance.currentUser?.uid,
            };

            try {
              final savedReminder = await _saveReminder(reminder);
              if (savedReminder != null) {
                await _scheduleNotification(savedReminder);
                successCount++;
              }
            } catch (e) {
              print('فشل في حفظ التذكير: ${reminder['title']} - $e');
            }
          }

          if (successCount > 0) {
            _showSnackBar('تم إنشاء $successCount تذكير بنجاح', Colors.green.shade400);
            await _fetchReminders();

            if (!_isPro) {
              await _incrementRecordingOnServer();
            }
          }
        } else {
          throw Exception('لم يتم التعرف على أي تذكيرات');
        }
      } else {
        throw Exception('فشل في معالجة الأمر الصوتي (${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar('خطأ في معالجة الأمر: $e', Colors.red.shade400);
    }
  }

  Future<Map<String, dynamic>?> _saveReminder(Map<String, dynamic> reminder) async {
    try {
      if (!await _checkConnectivity()) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }

      bool isEditing = reminder.containsKey('id') && reminder['id'] != null;
      Response response;

      if (isEditing) {
        response = await _dio.put(
          'https://mk-app.com/api-app/reminders.php',
          data: jsonEncode(reminder),
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      } else {
        response = await _dio.post(
          'https://mk-app.com/api-app/reminders.php',
          data: jsonEncode(reminder),
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (!isEditing && responseData is Map && responseData['id'] != null) {
          reminder['id'] = responseData['id'];
        }
        return reminder;
      } else {
        throw Exception('فشل في حفظ التذكير: ${response.data}');
      }
    } catch (e) {
      print('خطأ تفصيلي في حفظ التذكير: $e');
      _showSnackBar('خطأ في حفظ التذكير: $e', Colors.orange.shade400);
      return null;
    }
  }

  Future<void> _fetchReminders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _reminders = [];
      });
      return;
    }

    try {
      if (!await _checkConnectivity()) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }
      _cancelToken = CancelToken();
      final response = await _dio.get(
        'https://mk-app.com/api-app/reminders.php?userId=$userId',
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<Map<String, dynamic>> fetchedReminders = [];

        if (data is List) {
          fetchedReminders = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['reminders'] != null) {
          fetchedReminders = List<Map<String, dynamic>>.from(data['reminders']);
        }

        setState(() {
          _reminders = fetchedReminders;
        });
      }
    } catch (e) {
      print('خطأ في جلب التذكيرات: $e');
      _showSnackBar('فشل في جلب التذكيرات: $e', Colors.red.shade400);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReminderFromServer(Map<String, dynamic> reminder) async {
    try {
      if (!await _checkConnectivity()) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }
      if (reminder['id'] == null) return;

      await _dio.delete(
        'https://mk-app.com/api-app/reminders.php',
        data: jsonEncode({
          'id': reminder['id'],
          'userId': reminder['userId'],
        }),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } catch (e) {
      print('خطأ في حذف التذكير: $e');
    }
  }

  Future<void> _cancelNotification(Map<String, dynamic> reminder) async {
    try {
      int notificationId = reminder['id'] is int
          ? reminder['id']
          : int.tryParse(reminder['id'].toString()) ?? reminder.hashCode;
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
    } catch (e) {
      print('خطأ في إلغاء الإشعار: $e');
    }
  }

  Future<void> _scheduleNotification(Map<String, dynamic> reminder) async {
    try {
      final int notificationId = reminder['id'] is int
          ? reminder['id']
          : int.tryParse(reminder['id'].toString()) ?? reminder.hashCode;

      final date = DateTime.parse(reminder['date']);
      final time = reminder['time'];

      if (time == null) {
        print('خطأ: وقت التذكير null، هذا لا يجب أن يحدث.');
        return;
      }

      final notificationTime = tz.TZDateTime.from(
        DateTime.parse('${reminder['date']} $time'),
        tz.getLocation('Africa/Cairo'),
      );

      final tzNow = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledTime;

      if (notificationTime.isBefore(tzNow)) {
        print('وقت الإشعار قد فات: ${reminder['title']}. سيتم الإرسال الآن.');
        scheduledTime = tzNow.add(const Duration(seconds: 1));
      } else {
        scheduledTime = notificationTime;
      }

      String notificationBody = 'تذكير: ${reminder['title']}';

      final amount = reminder['amount'];
      double amountValue = 0.0;
      if (amount != null) {
        amountValue = double.tryParse(amount.toString()) ?? 0.0;
      }

      if (amountValue > 0) {
        // ⭐️ استخدام العملة المختارة
        notificationBody += ' - المبلغ: $amount $_selectedCurrency';
      }

      final details = reminder['details'];
      if (details != null && details.isNotEmpty) {
        notificationBody += '\nالتفاصيل: $details';
      }

      final androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Notifications for reminders',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          notificationBody,
          contentTitle: reminder['title'],
          summaryText: 'تذكير مالي',
        ),
      );
      final notificationDetails = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        reminder['title'],
        notificationBody,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('تم جدولة الإشعار: ${reminder['title']} at $scheduledTime');

    } catch(e) {
      print("خطأ فادح في جدولة الإشعار: $e");
      print("بيانات التذكير المسببة للخطأ: $reminder");
    }
  }

  Future<bool> _saveExpenseToExpensesAPI(Map<String, dynamic> expense) async {
    try {
      if (!await _checkConnectivity()) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }

      final response = await _dio.post(
        'https://mk-app.com/api-app/expenses.php',
        data: jsonEncode(expense),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      return (response.statusCode == 201 || response.statusCode == 200);

    } catch (e) {
      _showSnackBar('خطأ في حفظ المصروف: $e', Colors.orange.shade400);
      return false;
    }
  }

  void _showCompleteReminderDialog(Map<String, dynamic> reminder) {
    String selectedType = reminder['type'] ?? 'expense';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Text('إكمال التذكير'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هل تريد إضافة "${reminder['title']}" كمعاملة مالية؟',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'المبلغ: ${reminder['amount']} | الفئة: ${reminder['category']}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text('اختر نوع المعاملة:'),
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
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      _completeAndSaveExpense(reminder, selectedType);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تأكيد وإضافة'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _completeAndSaveExpense(Map<String, dynamic> reminder, String type) async {
    _showProcessingDialog();

    final newExpense = {
      'amount': reminder['amount']?.toString() ?? '0',
      'type': type,
      'category': reminder['category'] ?? 'أخرى',
      'notes': reminder['title'],
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    };

    bool success = await _saveExpenseToExpensesAPI(newExpense);

    if (success) {
      await _cancelNotification(reminder);
      await _deleteReminderFromServer(reminder);

      await _fetchReminders();
      _hideProcessingDialog();
      _showSnackBar('تم إكمال التذكير وإضافته للمعاملات ✓', Colors.green.shade400);
    } else {
      _hideProcessingDialog();
      _showSnackBar('فشل في حفظ المعاملة، يرجى المحاولة مرة أخرى', Colors.red.shade400);
    }
  }


  void _showManualAddDialog({Map<String, dynamic>? reminderToEdit}) {
    if (reminderToEdit == null && !_isPro) {
      _showUpgradeDialog();
      return;
    }

    final _formKey = GlobalKey<FormState>();
    bool isEditing = reminderToEdit != null;

    DateTime? _selectedDate;
    TimeOfDay? _selectedTime;
    String selectedType = 'expense';

    if (isEditing) {
      _manualTitleController.text = reminderToEdit!['title'] ?? '';
      _manualDetailsController.text = reminderToEdit['details'] ?? '';
      _manualAmountController.text = reminderToEdit['amount']?.toString() ?? '0';
      _selectedCategory = reminderToEdit['category'] ?? 'أخرى';
      selectedType = reminderToEdit['type'] ?? 'expense';
      try {
        _selectedDate = DateTime.parse(reminderToEdit['date']);
        if (reminderToEdit['time'] != null) {
          final parts = reminderToEdit['time'].split(':');
          _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (e) {
        _selectedDate = null;
        _selectedTime = null;
      }
    } else {
      _manualTitleController.clear();
      _manualDetailsController.clear();
      _manualAmountController.clear();
      _selectedCategory = 'أخرى';
      selectedType = 'expense';
      _selectedDate = null;
      _selectedTime = null;
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
                  Icon(Icons.edit_calendar_outlined, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(isEditing ? 'تعديل التذكير' : 'إضافة تذكير يدوي'),
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
                          ButtonSegment<String>(value: 'expense', label: Text('مصروف'), icon: Icon(Icons.arrow_upward_rounded)),
                          ButtonSegment<String>(value: 'income', label: Text('دخل'), icon: Icon(Icons.arrow_downward_rounded)),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setDialogState(() { selectedType = newSelection.first; });
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: selectedType == 'expense' ? Colors.red.shade100 : Colors.green.shade100,
                          selectedForegroundColor: selectedType == 'expense' ? Colors.red.shade900 : Colors.green.shade900,
                          foregroundColor: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _manualAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'المبلغ',
                          hintText: '0.00',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || double.tryParse(value) == null) {
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['name'],
                            child: Row(
                              children: [
                                Icon(_getCategoryIcon(cat['name']), color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(cat['name']),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() { _selectedCategory = value!; });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _manualTitleController,
                        decoration: InputDecoration(
                          labelText: 'العنوان',
                          hintText: 'اكتب عنوان التذكير',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'العنوان مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _manualDetailsController,
                        decoration: InputDecoration(
                          labelText: 'التفاصيل (اختياري)',
                          hintText: 'اكتب أي تفاصيل إضافية',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _selectedDate == null
                                    ? 'اختر التاريخ'
                                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                style: const TextStyle(fontSize: 13),
                              ),
                              onPressed: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                );
                                if (pickedDate != null) {
                                  setDialogState(() { _selectedDate = pickedDate; });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                _selectedTime == null
                                    ? 'اختر الوقت'
                                    : _selectedTime!.format(context),
                                style: const TextStyle(fontSize: 13),
                              ),
                              onPressed: () async {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null) {
                                  setDialogState(() { _selectedTime = pickedTime; });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
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
                      if (_selectedDate == null) {
                        _showSnackBar('يرجى اختيار التاريخ', Colors.orange.shade400);
                        return;
                      }

                      final TimeOfDay timeToSave = _selectedTime ?? const TimeOfDay(hour: 12, minute: 0);

                      Navigator.pop(context);
                      _showProcessingDialog();

                      final newReminder = {
                        'title': _manualTitleController.text,
                        'details': _manualDetailsController.text.isNotEmpty
                            ? _manualDetailsController.text
                            : null,
                        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        'time': '${timeToSave.hour.toString().padLeft(2, '0')}:${timeToSave.minute.toString().padLeft(2, '0')}',
                        'amount': double.tryParse(_manualAmountController.text) ?? 0.0,
                        'type': selectedType,
                        'category': _selectedCategory,
                        'userId': FirebaseAuth.instance.currentUser?.uid,
                        if (isEditing) 'id': reminderToEdit!['id'],
                      };

                      final savedReminder = await _saveReminder(newReminder);
                      _hideProcessingDialog();

                      if (savedReminder != null) {
                        await _scheduleNotification(savedReminder);
                        await _fetchReminders();
                        _showSnackBar(isEditing ? 'تم تعديل التذكير ✓' : 'تمت إضافة التذكير ✓', Colors.green.shade400);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  @override
  void dispose() {
    _manualTitleController.dispose();
    _manualDetailsController.dispose();
    _manualAmountController.dispose();
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

  // ⭐️ دالة للحصول على الأيقونة (تدعم الأيقونات المخصصة int)
  IconData _getCategoryIcon(String category) {
    final cat = _categories.firstWhere(
          (c) => c['name'] == category,
      orElse: () => _categories.last,
    );

    if (cat['icon'] is int) {
      return IconData(cat['icon'], fontFamily: 'MaterialIcons');
    }
    return cat['icon'];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'مرحبًا';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'التذكيرات',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        // ⭐️ شريط الإجراءات: البرو + زر الإعدادات ⭐️
        actions: [

          // 2. عداد التسجيلات
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                color: _isPro ? Colors.amber.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isPro ? Colors.amber : Colors.grey.shade300)
            ),
            child: Row(
              children: [
                Icon(Icons.mic, size: 16, color: _isPro ? Colors.amber.shade800 : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _isPro ? '∞' : '$_recordingCount',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _isPro ? Colors.amber.shade900 : Colors.black87
                  ),
                ),
              ],
            ),
          ),

          // 3. حالة الخطة (مجاني / برو)
          Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _isPro ? Colors.amber.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
              border: _isPro ? Border.all(color: Colors.amber.shade700, width: 1.5) : null,
            ),
            child: Text(
              _isPro ? 'PRO' : 'Free',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isPro ? Colors.amber.shade900 : Colors.blue,
                  fontSize: 12
              ),
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.grey.shade100,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCard(),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'التذكيرات القادمة',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_showSwipeHint && _reminders.isNotEmpty)
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
                          ' عند دفع او استلام الفلوس يمكنك الضغط على علامة الصخ لتحويلها لمعاملة',
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
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : _reminders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                  onRefresh: _fetchReminders,
                  child: ListView.builder(
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      return _buildReminderItem(_reminders[index], index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isRecording
          ? _buildRecordingControls()
          : _buildIdleMicButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatsCard() {
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.alarm,
                      color: Colors.blue.shade700, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'التذكيرات النشطة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_reminders.length}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
              Icons.alarm_off,
              size: 64,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد تذكيرات بعد',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'ابدأ بإضافة تذكير جديد باستخدام التسجيل الصوتي أو الإضافة اليدوية',
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

  String get12HourFormat(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final amPm = hour >= 12 ? 'م' : 'ص';
      hour = hour % 12 == 0 ? 12 : hour % 12;
      return '$hour:$minute $amPm';
    } catch (e) {
      return timeStr;
    }
  }

  bool _isReminderDue(Map<String, dynamic> reminder) {
    try {
      final reminderDate = DateTime.parse(reminder['date']);
      final now = DateTime.now();
      return reminderDate.year == now.year &&
          reminderDate.month == now.month &&
          reminderDate.day == now.day;
    } catch (e) {
      return false;
    }
  }


  void _deleteReminder(int index) {
    if (index < 0 || index >= _reminders.length) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'حذف التذكير',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا التذكير؟',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (index < 0 || index >= _reminders.length) return;

              final removedReminder = _reminders[index];

              setState(() {
                _reminders.removeAt(index);
              });

              await _cancelNotification(removedReminder);
              await _deleteReminderFromServer(removedReminder);

              _showSnackBar('تم حذف التذكير ✓', Colors.green.shade400);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'حذف',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> reminder, int index) {
    final itemKey = Key(reminder['id']?.toString() ?? reminder.hashCode.toString());
    final bool isDue = _isReminderDue(reminder);

    final type = reminder['type'] ?? 'expense';
    final categoryIconColor = type == 'income' ? Colors.green.shade700 : Colors.blue.shade700;

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
                          _showManualAddDialog(reminderToEdit: reminder);
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
                          _deleteReminder(index);
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
        onTap: () => Slidable.of(context)?.openEndActionPane(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categoryIconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(reminder['category'] ?? 'أخرى'),
                color: categoryIconColor,
                size: 26,
              ),
            ),
            title: Text(
              reminder['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  '${reminder['amount']} $_selectedCurrency  •  ${reminder['category']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      reminder['date'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (reminder['time'] != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        get12HourFormat(reminder['time']),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.check_circle_outline_rounded,
                color: isDue ? Colors.green.shade600 : Colors.grey.shade300,
                size: 30,
              ),
              onPressed: isDue
                  ? () {
                _showCompleteReminderDialog(reminder);
              }
                  : null,
              tooltip: isDue ? 'إكمال التذكير' : 'لا يمكن الإكمال قبل الميعاد',
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لعرض SnackBar
  void _showSnackBar(String message, Color backgroundColor) {
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
