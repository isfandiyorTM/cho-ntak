import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import '../i18n/translations.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final offsetHours = offsetMinutes ~/ 60;
    final offsetMins = offsetMinutes.abs() % 60;
    final sign = offsetHours >= 0 ? '+' : '-';
    final tzName = _offsetToTimezone(offsetHours);

    try {
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint(
        '✅ Timezone set: $tzName (UTC$sign${offsetHours.abs()}:${offsetMins.toString().padLeft(2, '0')})',
      );
    } catch (_) {
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
        description: "Daily finance reminders",
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
    );

    _initialized = true;
    debugPrint('✅ Notifications initialized. Timezone: $tzName');
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleMorningNotification({
    required Translations t,
    required double balance,
    required double totalExpense,
    required double budgetLimit,
    required String currencySymbol,
    int hour = 9,
    int minute = 0,
  }) async {
    if (!_initialized) await init();

    await _plugin.cancel(AppConstants.morningNotifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final title = _buildMorningTitle(t, balance, currencySymbol);
    final body = _buildMorningBody(
      t,
      balance: balance,
      expense: totalExpense,
      budget: budgetLimit,
      currencySymbol: currencySymbol,
    );

    await _plugin.zonedSchedule(
      AppConstants.morningNotifId,
      title,
      body,
      scheduled,
      _buildDetails(
        t,
        title: title,
        body: body,
        balance: balance,
        expense: totalExpense,
        budget: budgetLimit,
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint(
      '✅ Morning notification scheduled at $hour:${minute.toString().padLeft(2, '0')}',
    );
  }

  Future<void> scheduleEveningReminder({
    required Translations t,
    int hour = 20,
    int minute = 30,
  }) async {
    if (!_initialized) await init();

    await _plugin.cancel(AppConstants.eveningNotifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final title = _buildEveningTitle(t);
    final body = _buildEveningBody(t);

    await _plugin.zonedSchedule(
      AppConstants.eveningNotifId,
      title,
      body,
      scheduled,
      _buildDetails(
        t,
        title: title,
        body: body,
        balance: 0,
        expense: 0,
        budget: 0,
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint(
      '✅ Evening reminder scheduled at $hour:${minute.toString().padLeft(2, '0')}',
    );
  }

  Future<void> sendTestMorningNotification({
    required Translations t,
    required double balance,
    required double totalExpense,
    required double budgetLimit,
    required String currencySymbol,
  }) async {
    if (!_initialized) await init();

    final title = _buildMorningTitle(t, balance, currencySymbol);
    final body = _buildMorningBody(
      t,
      balance: balance,
      expense: totalExpense,
      budget: budgetLimit,
      currencySymbol: currencySymbol,
    );

    await _plugin.show(
      AppConstants.appOpenNotifId,
      title,
      body,
      _buildDetails(
        t,
        title: title,
        body: body,
        balance: balance,
        expense: totalExpense,
        budget: budgetLimit,
      ),
    );
  }

  Future<void> sendTestEveningNotification({
    required Translations t,
  }) async {
    if (!_initialized) await init();

    final title = _buildEveningTitle(t);
    final body = _buildEveningBody(t);

    await _plugin.show(
      AppConstants.appOpenNotifId + 1,
      title,
      body,
      _buildDetails(
        t,
        title: title,
        body: body,
        balance: 0,
        expense: 0,
        budget: 0,
      ),
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  Future<void> cancelMorning() async {
    await _plugin.cancel(AppConstants.morningNotifId);
  }

  Future<void> cancelEvening() async {
    await _plugin.cancel(AppConstants.eveningNotifId);
  }

  NotificationDetails _buildDetails(
      Translations t, {
        required String title,
        required String body,
        required double balance,
        required double expense,
        required double budget,
      }) {
    final color = _statusColor(balance, expense, budget);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notifChannelId,
        AppConstants.notifChannelName,
        channelDescription: _channelDescription(t),
        importance: Importance.high,
        priority: Priority.high,
        color: Color(color),
        colorized: true,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: _summaryText(t),
        ),
        playSound: false,
        enableVibration: true,
        ticker: _tickerText(t),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );
  }

  String _buildMorningTitle(Translations t, double balance, String symbol) {
    final sign = balance < 0 ? '-' : '';
    return switch (t.language) {
      AppLanguage.uz => '💰 Balans: $sign${_fmt(balance.abs(), symbol)}',
      AppLanguage.ru => '💰 Баланс: $sign${_fmt(balance.abs(), symbol)}',
      AppLanguage.en => '💰 Balance: $sign${_fmt(balance.abs(), symbol)}',
    };
  }

  String _buildMorningBody(
      Translations t, {
        required double balance,
        required double expense,
        required double budget,
        required String currencySymbol,
      }) {
    final lang = t.language;

    if (budget > 0 && expense > budget) {
      final over = _fmt(expense - budget, currencySymbol);
      return switch (lang) {
        AppLanguage.uz =>
        "Siz byudjetdan $over oshdingiz. Bugun xarajatni biroz kamaytirish foydali bo'ladi.",
        AppLanguage.ru =>
        "Вы превысили бюджет на $over. Сегодня лучше немного сократить расходы.",
        AppLanguage.en =>
        "You are over budget by $over. Consider slowing spending today.",
      };
    }

    if (budget > 0 && expense >= budget * 0.8) {
      final left = _fmt(budget - expense, currencySymbol);
      return switch (lang) {
        AppLanguage.uz =>
        "Byudjetingizda atigi $left qoldi. Xarajatni ehtiyotkorlik bilan qiling.",
        AppLanguage.ru =>
        "У вас осталось только $left бюджета. Тратьте осторожно.",
        AppLanguage.en =>
        "You have only $left left in your budget. Spend carefully.",
      };
    }

    if (balance < 0) {
      return switch (lang) {
        AppLanguage.uz =>
        "Balansingiz manfiy. Kichik daromad yoki kamroq xarajat foydali bo'ladi.",
        AppLanguage.ru =>
        "Ваш баланс отрицательный. Дополнительный доход или меньшие расходы помогут.",
        AppLanguage.en =>
        "Your balance is negative. A small income or fewer expenses could help.",
      };
    }

    if (balance == 0) {
      return switch (lang) {
        AppLanguage.uz =>
        "Balansingiz nol. Yangi daromadlarni kiritishni unutmang.",
        AppLanguage.ru =>
        "Ваш баланс равен нулю. Не забудьте добавить новые доходы.",
        AppLanguage.en =>
        "Your balance is zero. Do not forget to add new income.",
      };
    }

    if (budget > 0 && expense < budget * 0.5) {
      return switch (lang) {
        AppLanguage.uz =>
        "Zo'r! Bugun byudjetingizning yarmidan kamini sarfladingiz.",
        AppLanguage.ru =>
        "Отлично! Сегодня вы потратили меньше половины бюджета.",
        AppLanguage.en =>
        "Great! You have spent less than half of your budget today.",
      };
    }

    return switch (lang) {
      AppLanguage.uz =>
      "Bugungi holat yaxshi. Xarajatlarni kuzatishda davom eting.",
      AppLanguage.ru =>
      "Сегодня всё выглядит хорошо. Продолжайте следить за расходами.",
      AppLanguage.en =>
      "Your finances look stable today. Keep tracking them.",
    };
  }

  String _buildEveningTitle(Translations t) {
    return switch (t.language) {
      AppLanguage.uz => '📝 Kun yakuni eslatmasi',
      AppLanguage.ru => '📝 Вечернее напоминание',
      AppLanguage.en => '📝 End-of-day reminder',
    };
  }

  String _buildEveningBody(Translations t) {
    return switch (t.language) {
      AppLanguage.uz =>
      "Bugungi kirim-chiqimlaringizni ko'rib chiqing va unutib qoldirganlaringizni qo'shing.",
      AppLanguage.ru =>
      'Проверьте транзакции за сегодня и добавьте то, что могли пропустить.',
      AppLanguage.en =>
      'Please review today\'s transactions and add anything you may have missed.',
    };
  }

  String _channelDescription(Translations t) {
    return switch (t.language) {
      AppLanguage.uz => "Kunlik moliyaviy eslatmalar",
      AppLanguage.ru => "Ежедневные финансовые напоминания",
      AppLanguage.en => "Daily finance reminders",
    };
  }

  String _summaryText(Translations t) {
    return switch (t.language) {
      AppLanguage.uz => "Cho'ntak",
      AppLanguage.ru => "Кошелёк",
      AppLanguage.en => "Wallet",
    };
  }

  String _tickerText(Translations t) {
    return switch (t.language) {
      AppLanguage.uz => "Moliyaviy eslatma",
      AppLanguage.ru => "Финансовое напоминание",
      AppLanguage.en => "Finance reminder",
    };
  }

  int _statusColor(double balance, double expense, double budget) {
    if (budget > 0 && expense > budget) return 0xFFE53935;
    if (budget > 0 && expense >= budget * 0.8) return 0xFFFF8F00;
    if (balance < 0) return 0xFFE53935;
    return 0xFFFFD700;
  }

  String _fmt(double amount, String symbol) {
    final abs = amount.abs();
    if (abs >= 1000000) return "$symbol${_n(abs / 1000000)}M";
    if (abs >= 1000) return "$symbol${_n(abs / 1000)}K";
    return "$symbol${abs.toStringAsFixed(0)}";
  }

  String _n(double v) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  static String _offsetToTimezone(int offsetHours) {
    const map = {
      5: 'Asia/Tashkent',
      3: 'Europe/Moscow',
      6: 'Asia/Almaty',
      4: 'Asia/Dubai',
      8: 'Asia/Shanghai',
      9: 'Asia/Tokyo',
      0: 'Europe/London',
      1: 'Europe/Berlin',
      2: 'Europe/Kyiv',
      -5: 'America/New_York',
      -8: 'America/Los_Angeles',
    };
    return map[offsetHours] ?? 'UTC';
  }
}