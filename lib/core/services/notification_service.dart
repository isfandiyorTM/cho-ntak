import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../constants/app_constants.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Init ─────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezones using device's UTC offset from Dart built-in
    tz_data.initializeTimeZones();
    final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final offsetHours   = offsetMinutes ~/ 60;
    final offsetMins    = offsetMinutes.abs() % 60;
    final sign          = offsetHours >= 0 ? '+' : '-';
    // Map offset to IANA timezone name
    // Tashkent = UTC+5, Moscow = UTC+3, etc.
    final tzName = _offsetToTimezone(offsetHours);
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('✅ Timezone set: $tzName (UTC$sign${offsetHours.abs()}:${offsetMins.toString().padLeft(2,'0')})');
    } catch (_) {
      // Fallback to UTC if timezone not found
      tz.setLocalLocation(tz.UTC);
      debugPrint('⚠️ Timezone fallback to UTC');
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notifChannelId,
        AppConstants.notifChannelName,
        description: "Cho'ntak kunlik balans eslatmasi",
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
    );

    _initialized = true;
    debugPrint('✅ Notifications initialized. Timezone: $tzName');
  }

  // ── Request permission ────────────────────────────────────
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Schedule daily notification ───────────────────────────
  Future<void> scheduleDailyNotification({
    required double balance,
    required double totalExpense,
    required double budgetLimit,
    required String currencySymbol,
    int hour = 9,
    int minute = 0,
  }) async {
    if (!_initialized) await init();

    // Cancel existing before rescheduling
    await _plugin.cancel(AppConstants.morningNotifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);

    // If time already passed today → schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    debugPrint('📅 Scheduling daily notification for: $scheduled (local: ${tz.local.name})');

    await _plugin.zonedSchedule(
      AppConstants.morningNotifId,
      _buildTitle(balance, currencySymbol),
      _buildBody(balance, totalExpense, budgetLimit),
      scheduled,
      _buildDetails(balance, budgetLimit, totalExpense),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      // No matchDateTimeComponents — fires once at exact time with TODAY's data.
      // App reschedules on next resume (WidgetsBindingObserver) with fresh data.
    );

    debugPrint('✅ Daily notification scheduled at $hour:${minute.toString().padLeft(2,'0')}');
  }

  // ── Test notification ─────────────────────────────────────
  Future<void> sendTestNotification({
    required double balance,
    required double totalExpense,
    required double budgetLimit,
    required String currencySymbol,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      AppConstants.appOpenNotifId,
      _buildTitle(balance, currencySymbol),
      _buildBody(balance, totalExpense, budgetLimit),
      _buildDetails(balance, budgetLimit, totalExpense),
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Notification details ──────────────────────────────────
  NotificationDetails _buildDetails(
      double balance, double budgetLimit, double expense) {
    final color = _statusColor(balance, expense, budgetLimit);
    final body  = _buildBody(balance, expense, budgetLimit);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notifChannelId,
        AppConstants.notifChannelName,
        channelDescription: "Cho'ntak kunlik balans eslatmasi",
        importance: Importance.high,
        priority: Priority.high,
        color: Color(color),
        colorized: true,
        largeIcon:
        const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: _buildSubtitle(balance, expense, budgetLimit),
          summaryText: "Cho'ntak",
        ),
        playSound: false,
        enableVibration: true,
        ticker: "Cho'ntak balans",
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );
  }

  String _buildTitle(double balance, String symbol) {
    final sign = balance < 0 ? '-' : '';
    return "👛 Cho'ntagingizda: $sign${_fmt(balance.abs(), symbol)}";
  }

  String _buildSubtitle(double balance, double expense, double budget) {
    if (budget > 0 && expense > budget)        return "⚠️ Byudjet oshdi!";
    if (budget > 0 && expense >= budget * 0.8) return "🔶 Byudjet tugayapti";
    if (balance < 0)                           return "📉 Balans manfiy";
    if (balance == 0)                          return "😐 Balans nol";
    return "✅ Moliyangiz yaxshi";
  }

  String _buildBody(double balance, double expense, double budget) {
    if (budget > 0 && expense > budget) {
      return "Oylik byudjetdan ${_fmt(expense - budget, '')} oshib ketdi! "
          "Bugun xarajatlarni kamaytiring.";
    }
    if (budget > 0 && expense >= budget * 0.8) {
      return "Byudjetingizdan faqat ${_fmt(budget - expense, '')} qoldi. "
          "Ehtiyot bo'ling!";
    }
    if (balance < 0) {
      return "Balansingiz manfiy! Daromad qo'shing yoki xarajatlarni kamaytiring.";
    }
    if (balance == 0) {
      return "Balansingiz nol. Yangi daromadlarni kiritishni unutmang.";
    }
    if (budget > 0 && expense < budget * 0.5) {
      return "Zo'r! Byudjetingizning yarmidan kamini sarfladingiz. Shunday davom eting!";
    }
    return "Bugun ham cho'ntagingizga qarab ish qiling. Har bir so'm muhim!";
  }

  int _statusColor(double balance, double expense, double budget) {
    if (budget > 0 && expense > budget)        return 0xFFE53935;
    if (budget > 0 && expense >= budget * 0.8) return 0xFFFF8F00;
    if (balance < 0)                           return 0xFFE53935;
    return 0xFFFFD700;
  }

  String _fmt(double amount, String symbol) {
    final abs = amount.abs();
    if (abs >= 1000000) return "$symbol${_n(abs / 1000000)}M";
    if (abs >= 1000)    return "$symbol${_n(abs / 1000)}K";
    return "$symbol${abs.toStringAsFixed(0)}";
  }

  String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  // Map UTC offset (hours) to IANA timezone name
  static String _offsetToTimezone(int offsetHours) {
    const map = {
      5:  'Asia/Tashkent',   // Uzbekistan
      3:  'Europe/Moscow',   // Russia
      6:  'Asia/Almaty',     // Kazakhstan
      4:  'Asia/Dubai',      // UAE
      8:  'Asia/Shanghai',   // China
      9:  'Asia/Tokyo',      // Japan
      0:  'Europe/London',   // UK
      1:  'Europe/Berlin',   // Germany
      2:  'Europe/Kiev',     // Ukraine
      -5: 'America/New_York',
      -8: 'America/Los_Angeles',
    };
    return map[offsetHours] ?? 'UTC';
  }
}